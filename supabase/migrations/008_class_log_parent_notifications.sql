-- =============================================================================
-- SSCS Migration 008: Notify parents for class broadcasts as well as student logs
-- Depends on: 007
-- =============================================================================

CREATE OR REPLACE FUNCTION public.notify_parents_of_activity_log()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    parent_record RECORD;
    student_name TEXT;
    notification_title TEXT;
    notification_body TEXT;
    notification_type TEXT;
BEGIN
    -- A student log is personal, even though it also belongs to a class.
    IF NEW.student_id IS NOT NULL THEN
        SELECT concat_ws(' ', first_name, middle_name, last_name)
        INTO student_name
        FROM public.students
        WHERE id = NEW.student_id;

        notification_title := 'New student log';
        notification_type := 'student_log';
        notification_body := format(
            'A new %s log was added for %s: %s',
            replace(NEW.activity_type, '_', ' '),
            coalesce(student_name, 'your student'),
            NEW.title
        );

        IF NEW.description IS NOT NULL AND btrim(NEW.description) <> '' THEN
            notification_body := notification_body || E'\n' || NEW.description;
        END IF;

        FOR parent_record IN
            SELECT parent_id
            FROM public.parent_students
            WHERE student_id = NEW.student_id AND is_active = true
        LOOP
            INSERT INTO public.notifications (
                user_id, title, body, type, reference_type, reference_id, action_url
            ) VALUES (
                parent_record.parent_id,
                notification_title,
                notification_body,
                notification_type,
                'activities',
                NEW.id,
                '/parent/activities'
            );
        END LOOP;

        RETURN NEW;
    END IF;

    -- A class log is broadcast to each active parent with a child in that class.
    IF NEW.class_id IS NOT NULL THEN
        notification_title := 'New class log';
        notification_type := 'class_log';
        notification_body := format(
            'A new %s update was added for your child''s class: %s',
            replace(NEW.activity_type, '_', ' '),
            NEW.title
        );

        IF NEW.description IS NOT NULL AND btrim(NEW.description) <> '' THEN
            notification_body := notification_body || E'\n' || NEW.description;
        END IF;

        FOR parent_record IN
            SELECT DISTINCT ps.parent_id
            FROM public.parent_students ps
            INNER JOIN public.student_enrollments se
                ON se.student_id = ps.student_id
            WHERE ps.is_active = true
              AND se.status = 'active'
              AND se.class_id = NEW.class_id
        LOOP
            INSERT INTO public.notifications (
                user_id, title, body, type, reference_type, reference_id, action_url
            ) VALUES (
                parent_record.parent_id,
                notification_title,
                notification_body,
                notification_type,
                'activities',
                NEW.id,
                '/parent/activities'
            );
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_activities_notify_parents ON public.activities;
CREATE TRIGGER trg_activities_notify_parents
    AFTER INSERT ON public.activities
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_parents_of_activity_log();
