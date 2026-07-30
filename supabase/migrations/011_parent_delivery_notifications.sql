-- =============================================================================
-- SSCS Migration 011: Deliver parent alerts for messages, attendance and results
-- =============================================================================

CREATE OR REPLACE FUNCTION public.notify_parents_of_attendance()
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
BEGIN
    SELECT concat_ws(' ', first_name, middle_name, last_name)
    INTO student_name
    FROM public.students
    WHERE id = NEW.student_id;

    notification_title := CASE
        WHEN TG_OP = 'INSERT' THEN 'Attendance recorded'
        ELSE 'Attendance updated'
    END;
    notification_body := format(
        '%s was marked %s for %s.',
        coalesce(student_name, 'Your child'),
        replace(NEW.status::text, '_', ' '),
        to_char(NEW.date, 'FMMonth FMDD, YYYY')
    );

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
            'attendance',
            'attendance',
            NEW.id,
            '/parent/attendance'
        );
    END LOOP;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_attendance_notify_parents ON public.attendance;
CREATE TRIGGER trg_attendance_notify_parents
    AFTER INSERT OR UPDATE OF status, date ON public.attendance
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_parents_of_attendance();

CREATE OR REPLACE FUNCTION public.notify_parents_of_result()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    parent_record RECORD;
    student_name TEXT;
    subject_name TEXT;
    notification_title TEXT;
    notification_body TEXT;
    score TEXT;
BEGIN
    SELECT concat_ws(' ', first_name, middle_name, last_name)
    INTO student_name
    FROM public.students
    WHERE id = NEW.student_id;

    SELECT subjects.name
    INTO subject_name
    FROM public.teacher_assignments
    INNER JOIN public.subjects
        ON subjects.id = teacher_assignments.subject_id
    WHERE teacher_assignments.id = NEW.teacher_assignment_id;

    score := CASE
        WHEN NEW.marks_obtained IS NOT NULL AND NEW.total_marks IS NOT NULL
            THEN trim(to_char(NEW.marks_obtained, 'FM999999990.##'))
                || '/' || trim(to_char(NEW.total_marks, 'FM999999990.##'))
        WHEN NEW.grade IS NOT NULL THEN NEW.grade
        ELSE 'recorded'
    END;
    notification_title := CASE
        WHEN TG_OP = 'INSERT' THEN 'New result posted'
        ELSE 'Result updated'
    END;
    notification_body := format(
        '%s''s %s result for %s: %s.',
        coalesce(student_name, 'Your child'),
        coalesce(NEW.exam_type::text, 'assessment'),
        coalesce(subject_name, 'a subject'),
        score
    );

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
            'result',
            'results',
            NEW.id,
            '/parent/results'
        );
    END LOOP;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_results_notify_parents ON public.results;
CREATE TRIGGER trg_results_notify_parents
    AFTER INSERT OR UPDATE ON public.results
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_parents_of_result();

CREATE OR REPLACE FUNCTION public.notify_message_recipient()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    recipient_id UUID;
    sender_name TEXT;
BEGIN
    SELECT CASE
        WHEN participant1_id = NEW.sender_id THEN participant2_id
        ELSE participant1_id
    END
    INTO recipient_id
    FROM public.conversations
    WHERE id = NEW.conversation_id;

    IF recipient_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT concat_ws(' ', first_name, last_name)
    INTO sender_name
    FROM public.profiles
    WHERE id = NEW.sender_id;

    INSERT INTO public.notifications (
        user_id, title, body, type, reference_type, reference_id, action_url
    ) VALUES (
        recipient_id,
        format('New message from %s', coalesce(sender_name, 'a school contact')),
        left(NEW.content, 250),
        'message',
        'messages',
        NEW.id,
        CASE
            WHEN (SELECT role FROM public.profiles WHERE id = recipient_id) = 'parent'
                THEN '/parent/messages'
            ELSE '/teacher/messages'
        END
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_messages_notify_recipient ON public.messages;
CREATE TRIGGER trg_messages_notify_recipient
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_message_recipient();
