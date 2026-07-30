-- =============================================================================
-- SSCS Migration 010: Realtime updates and reliable message delivery
-- =============================================================================

-- Message inserts must not fail because the timestamp update runs under the
-- sender's RLS role. The trigger only updates the conversation owning NEW.id.
CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.conversations
    SET last_message_at = NEW.created_at
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$;

-- Realtime is opt-in per table in Supabase's publication.
DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOREACH table_name IN ARRAY ARRAY[
        'academic_years', 'classes', 'subjects', 'teachers', 'students',
        'teacher_assignments', 'student_enrollments', 'parent_students',
        'attendance', 'results', 'activities', 'announcements',
        'announcement_reads', 'conversations', 'messages', 'notifications'
    ]
    LOOP
        IF NOT EXISTS (
            SELECT 1
            FROM pg_publication_tables
            WHERE pubname = 'supabase_realtime'
              AND schemaname = 'public'
              AND tablename = table_name
        ) THEN
            EXECUTE format(
                'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',
                table_name
            );
        END IF;
    END LOOP;
END;
$$;
