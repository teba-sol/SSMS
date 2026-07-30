-- =============================================================================
-- SSCS Migration 007: Secure student logs and notify linked parents
-- Depends on: 001-006
-- =============================================================================

-- Migration 006 adds this column. Keep this statement so this migration is
-- safe to run on databases where it was not applied separately.
ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS student_id UUID REFERENCES public.students(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_activities_student_id
    ON public.activities(student_id);

-- Student logs are visible only to their linked parents and assigned teachers.
-- Class and school activities keep their existing visibility rules.
DROP POLICY IF EXISTS "activities_select_authenticated" ON public.activities;
DROP POLICY IF EXISTS "activities_admin_all" ON public.activities;
DROP POLICY IF EXISTS "activities_teacher_insert" ON public.activities;

CREATE POLICY "activities_select_authenticated"
    ON public.activities FOR SELECT
    TO authenticated
    USING (
        public.get_user_role() = 'administrator'
        OR (
            student_id IS NOT NULL
            AND (
                student_id IN (SELECT public.get_teacher_student_ids())
                OR student_id IN (SELECT public.get_parent_student_ids())
            )
        )
        OR (
            student_id IS NULL
            AND (
                class_id IS NULL
                OR class_id IN (SELECT public.get_teacher_class_ids())
                OR class_id IN (SELECT public.get_parent_class_ids())
            )
        )
    );

CREATE POLICY "activities_admin_all"
    ON public.activities FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator')
    WITH CHECK (public.get_user_role() = 'administrator');

CREATE POLICY "activities_teacher_insert"
    ON public.activities FOR INSERT
    TO authenticated
    WITH CHECK (
        public.get_user_role() = 'teacher'
        AND (
            (student_id IS NULL AND (
                class_id IS NULL
                OR class_id IN (SELECT public.get_teacher_class_ids())
            ))
            OR (
                student_id IS NOT NULL
                AND student_id IN (SELECT public.get_teacher_student_ids())
                AND class_id IN (SELECT public.get_teacher_class_ids())
            )
        )
    );

CREATE OR REPLACE FUNCTION public.notify_parents_of_student_log()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    parent_record RECORD;
    student_name TEXT;
    notification_body TEXT;
BEGIN
    SELECT concat_ws(' ', first_name, middle_name, last_name)
    INTO student_name
    FROM public.students
    WHERE id = NEW.student_id;

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
            'New student log',
            notification_body,
            'student_log',
            'activities',
            NEW.id,
            '/parent/activities'
        );
    END LOOP;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_activities_notify_parents ON public.activities;
CREATE TRIGGER trg_activities_notify_parents
    AFTER INSERT ON public.activities
    FOR EACH ROW
    WHEN (NEW.student_id IS NOT NULL)
    EXECUTE FUNCTION public.notify_parents_of_student_log();
