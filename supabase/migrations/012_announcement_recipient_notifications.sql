CREATE OR REPLACE FUNCTION public.notify_announcement_recipients()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    notification_title TEXT;
BEGIN
    IF NOT NEW.is_published THEN
        RETURN NEW;
    END IF;

    notification_title := 'Announcement updated';
    IF TG_OP = 'INSERT' THEN
        notification_title := 'New announcement';
    ELSIF NOT OLD.is_published THEN
        notification_title := 'New announcement';
    END IF;

    INSERT INTO public.notifications (
        user_id, title, body, type, reference_type, reference_id, action_url
    )
    SELECT DISTINCT
        profiles.id,
        notification_title,
        NEW.content,
        'announcement',
        'announcements',
        NEW.id,
        CASE
            WHEN profiles.role = 'parent' THEN '/parent/notifications'
            ELSE '/teacher/notifications'
        END
    FROM public.profiles
    WHERE profiles.is_active = true
      AND profiles.role IN ('parent', 'teacher')
      AND (
          NEW.target_audience = 'all'
          OR NEW.target_audience::text = profiles.role::text || 's'
      )
      AND (
          NEW.class_id IS NULL
          OR (
              profiles.role = 'parent'
              AND EXISTS (
                  SELECT 1
                  FROM public.parent_students
                  INNER JOIN public.student_enrollments
                      ON student_enrollments.student_id = parent_students.student_id
                  WHERE parent_students.parent_id = profiles.id
                    AND parent_students.is_active = true
                    AND student_enrollments.status = 'active'
                    AND student_enrollments.class_id = NEW.class_id
              )
          )
          OR (
              profiles.role = 'teacher'
              AND EXISTS (
                  SELECT 1
                  FROM public.teachers
                  INNER JOIN public.teacher_assignments
                      ON teacher_assignments.teacher_id = teachers.id
                  WHERE teachers.profile_id = profiles.id
                    AND teacher_assignments.class_id = NEW.class_id
              )
          )
      );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_announcements_notify_recipients ON public.announcements;
CREATE TRIGGER trg_announcements_notify_recipients
    AFTER INSERT OR UPDATE OF is_published, title, content, target_audience, class_id
    ON public.announcements
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_announcement_recipients();
