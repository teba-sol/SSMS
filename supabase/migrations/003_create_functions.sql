-- =============================================================================
-- SSCS Migration 003: Functions & Triggers
-- Student Status Checkup System
-- =============================================================================
-- Depends on: 001 (tables), 002 (operations tables)
-- =============================================================================

-- =============================================================================
-- 1. AUTO-UPDATE updated_at
-- =============================================================================
-- Generic trigger. Attach to any table with an updated_at column.

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.update_updated_at() IS 'Sets updated_at to now() on every UPDATE.';

-- Attach to all tables with updated_at
CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_academic_years_updated_at
    BEFORE UPDATE ON public.academic_years
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_classes_updated_at
    BEFORE UPDATE ON public.classes
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_teachers_updated_at
    BEFORE UPDATE ON public.teachers
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_students_updated_at
    BEFORE UPDATE ON public.students
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_student_enrollments_updated_at
    BEFORE UPDATE ON public.student_enrollments
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_parent_students_updated_at
    BEFORE UPDATE ON public.parent_students
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_attendance_updated_at
    BEFORE UPDATE ON public.attendance
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_results_updated_at
    BEFORE UPDATE ON public.results
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_activities_updated_at
    BEFORE UPDATE ON public.activities
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER trg_announcements_updated_at
    BEFORE UPDATE ON public.announcements
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =============================================================================
-- 2. SYNC EMAIL FROM AUTH.USERS TO PROFILES
-- =============================================================================
-- If a user's email is updated in auth.users, sync it to profiles.

-- NOTE: There is NO trigger to auto-create profiles on auth.users INSERT.
-- All user creation MUST go through edge functions, which create both the
-- auth user AND the profile in one step with the correct role.
-- This prevents any temporary role inconsistency.

CREATE OR REPLACE FUNCTION public.handle_user_email_update()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.email IS DISTINCT FROM NEW.email THEN
        UPDATE public.profiles
        SET email = NEW.email
        WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.handle_user_email_update() IS 'Syncs email changes from auth.users to profiles.';

CREATE TRIGGER on_auth_user_email_updated
    AFTER UPDATE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_user_email_update();

-- =============================================================================
-- 3. ENFORCE SINGLE CURRENT ACADEMIC YEAR
-- =============================================================================
-- When is_current is set to true on INSERT, set all others to false.
-- Direct UPDATE on is_current is BLOCKED — use set_current_academic_year() instead.

CREATE OR REPLACE FUNCTION public.enforce_single_current_year()
RETURNS TRIGGER AS $$
BEGIN
    -- On INSERT: if new row is current, unset all others
    IF TG_OP = 'INSERT' AND NEW.is_current = true THEN
        UPDATE public.academic_years
        SET is_current = false
        WHERE id != NEW.id AND is_current = true;
    END IF;

    -- On UPDATE: block manual changes to is_current
    IF TG_OP = 'UPDATE' AND OLD.is_current IS DISTINCT FROM NEW.is_current THEN
        RAISE EXCEPTION 'Direct UPDATE on is_current is not allowed. Use set_current_academic_year() instead.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.enforce_single_current_year() IS 'Blocks direct UPDATE on is_current. Only set_current_academic_year() can change it.';

CREATE TRIGGER trg_enforce_single_current_year
    BEFORE INSERT OR UPDATE ON public.academic_years
    FOR EACH ROW EXECUTE FUNCTION public.enforce_single_current_year();

-- =============================================================================
-- 4. SET CURRENT ACADEMIC YEAR (SERVER-SIDE ONLY)
-- =============================================================================
-- SECURITY DEFINER: The ONLY way to change the current academic year.
-- Unsets all other current years, then sets the new one.

CREATE OR REPLACE FUNCTION public.set_current_academic_year(p_year_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Use session variable to signal the trigger to allow this update
    PERFORM set_config('app.setting_current_year', 'true', true);

    -- Unset all current years
    UPDATE public.academic_years
    SET is_current = false
    WHERE is_current = true;

    -- Set the new current year
    UPDATE public.academic_years
    SET is_current = true
    WHERE id = p_year_id;

    -- Clear the signal
    PERFORM set_config('app.setting_current_year', 'false', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.set_current_academic_year(UUID) IS 'The ONLY way to change the current academic year. SECURITY DEFINER.';

-- Update the trigger to respect the bypass signal
CREATE OR REPLACE FUNCTION public.enforce_single_current_year()
RETURNS TRIGGER AS $$
BEGIN
    -- Allow bypass when called from set_current_academic_year()
    IF current_setting('app.setting_current_year', true) = 'true' THEN
        RETURN NEW;
    END IF;

    -- On INSERT: if new row is current, unset all others
    IF TG_OP = 'INSERT' AND NEW.is_current = true THEN
        PERFORM set_config('app.setting_current_year', 'true', true);
        UPDATE public.academic_years
        SET is_current = false
        WHERE id != NEW.id AND is_current = true;
        PERFORM set_config('app.setting_current_year', 'false', true);
    END IF;

    -- On UPDATE: block manual changes to is_current
    IF TG_OP = 'UPDATE' AND OLD.is_current IS DISTINCT FROM NEW.is_current THEN
        RAISE EXCEPTION 'Direct UPDATE on is_current is not allowed. Use set_current_academic_year() instead.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 5. UPDATE CONVERSATION LAST_MESSAGE_AT
-- =============================================================================
-- When a new message is inserted, update the parent conversation's last_message_at.

CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.conversations
    SET last_message_at = NEW.created_at
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.update_conversation_last_message() IS 'Updates conversations.last_message_at when a new message is sent.';

CREATE TRIGGER trg_messages_update_conversation
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION public.update_conversation_last_message();

-- =============================================================================
-- 6. RECORD LAST LOGIN
-- =============================================================================
-- Called from the app or edge function after successful authentication.
-- Not a trigger — called explicitly to avoid timing issues.

CREATE OR REPLACE FUNCTION public.record_last_login(user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.profiles
    SET last_login = now()
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.record_last_login(UUID) IS 'Updates last_login timestamp. Call after successful auth.';

-- =============================================================================
-- 7. AUTO-CREATE STUDENT ENROLLMENT HELPER
-- =============================================================================
-- Utility function to check if a teacher is assigned to a given class+subject.

CREATE OR REPLACE FUNCTION public.is_teacher_assigned(
    p_teacher_id UUID,
    p_class_id UUID,
    p_subject_id UUID
)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.teacher_assignments
        WHERE teacher_id = p_teacher_id
          AND class_id = p_class_id
          AND subject_id = p_subject_id
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION public.is_teacher_assigned(UUID, UUID, UUID) IS 'Checks if a teacher is assigned to a class+subject combination.';

-- =============================================================================
-- 8. GET CURRENT ACADEMIC YEAR
-- =============================================================================
-- Returns the ID of the current academic year. Used in RLS and app logic.

CREATE OR REPLACE FUNCTION public.get_current_academic_year()
RETURNS UUID AS $$
    SELECT id FROM public.academic_years
    WHERE is_current = true
    LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION public.get_current_academic_year() IS 'Returns the UUID of the current academic year.';

-- =============================================================================
-- 9. GET USER ROLE
-- =============================================================================
-- Returns the role of the currently authenticated user.
-- Used heavily in RLS policies.

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS user_role AS $$
    SELECT role FROM public.profiles
    WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION public.get_user_role() IS 'Returns the role of the current authenticated user.';

-- =============================================================================
-- 10. GET USER PROFILE ID
-- =============================================================================
-- Returns the profile ID of the currently authenticated user.
-- In this system, profile ID = auth.uid(), but this helper
-- makes RLS policies more readable.

CREATE OR REPLACE FUNCTION public.get_user_id()
RETURNS UUID AS $$
    SELECT auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION public.get_user_id() IS 'Returns auth.uid() of the current user.';

-- =============================================================================
-- 11. GET TEACHER ID FOR CURRENT USER
-- =============================================================================
-- Returns the teacher record ID for the current user.
-- Returns NULL if the user is not a teacher.

CREATE OR REPLACE FUNCTION public.get_teacher_id()
RETURNS UUID AS $$
    SELECT t.id FROM public.teachers t
    WHERE t.profile_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION public.get_teacher_id() IS 'Returns the teacher record ID for the current user. NULL if not a teacher.';

-- =============================================================================
-- 12. GET PARENT PROFILE IDS FOR STUDENT
-- =============================================================================
-- Returns all profile IDs of parents linked to a given student.

CREATE OR REPLACE FUNCTION public.get_student_parent_ids(p_student_id UUID)
RETURNS SETOF UUID AS $$
    SELECT ps.parent_id FROM public.parent_students ps
    WHERE ps.student_id = p_student_id
      AND ps.is_active = true;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION public.get_student_parent_ids(UUID) IS 'Returns profile IDs of active parents for a student.';

-- =============================================================================
-- 13. ASSIGN USER ROLE (SERVER-SIDE ONLY)
-- =============================================================================
-- SECURITY DEFINER: Only callable from edge functions or other trusted server code.
-- This prevents clients from setting their own role during signup.

CREATE OR REPLACE FUNCTION public.assign_user_role(
    p_user_id UUID,
    p_role user_role
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.profiles
    SET role = p_role
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.assign_user_role(UUID, user_role) IS 'Changes an existing user role. SECURITY DEFINER — only callable from server-side code. Edge functions set the role at creation time.';

-- =============================================================================
-- 14. DEACTIVATE USER TOKENS ON LOGOUT
-- =============================================================================
-- SECURITY DEFINER: Called from the logout edge function.
-- Sets all of a user's device tokens to inactive so old devices stop receiving push.

CREATE OR REPLACE FUNCTION public.deactivate_user_tokens(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    deactivated_count INTEGER;
BEGIN
    UPDATE public.device_tokens
    SET is_active = false,
        logged_out_at = now()
    WHERE user_id = p_user_id
      AND is_active = true;

    GET DIAGNOSTICS deactivated_count = ROW_COUNT;
    RETURN deactivated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.deactivate_user_tokens(UUID) IS 'Deactivates all FCM tokens for a user on logout. Sets logged_out_at. Returns count.';

-- =============================================================================
-- 15. PREVENT DELETION OF CURRENT ACADEMIC YEAR
-- =============================================================================
-- Blocks DELETE on academic_years where is_current = true.
-- Admin must first mark another year as current before deleting.

CREATE OR REPLACE FUNCTION public.prevent_delete_current_year()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.is_current = true THEN
        RAISE EXCEPTION 'Cannot delete the current academic year. Mark another year as current first.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.prevent_delete_current_year() IS 'Blocks deletion of the current academic year. Must unmark is_current first.';

CREATE TRIGGER trg_prevent_delete_current_year
    BEFORE DELETE ON public.academic_years
    FOR EACH ROW EXECUTE FUNCTION public.prevent_delete_current_year();

-- =============================================================================
-- 16. CREATE NOTIFICATION (SERVER-SIDE ONLY)
-- =============================================================================
-- SECURITY DEFINER: Only edge functions should create notifications.
-- This function bypasses RLS and is the ONLY way to insert into notifications.

CREATE OR REPLACE FUNCTION public.create_notification(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT,
    p_type TEXT,
    p_reference_type TEXT DEFAULT NULL,
    p_reference_id UUID DEFAULT NULL,
    p_action_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    new_id UUID;
BEGIN
    INSERT INTO public.notifications (
        user_id, title, body, type,
        reference_type, reference_id, action_url
    ) VALUES (
        p_user_id, p_title, p_body, p_type,
        p_reference_type, p_reference_id, p_action_url
    ) RETURNING id INTO new_id;

    RETURN new_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.create_notification(UUID, TEXT, TEXT, TEXT, TEXT, UUID, TEXT) IS 'Creates a notification. SECURITY DEFINER — only callable from server-side code.';

-- =============================================================================
-- DONE: Functions and triggers created.
-- Next: Migration 004 for RLS policies.
-- =============================================================================
