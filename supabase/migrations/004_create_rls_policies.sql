-- =============================================================================
-- SSCS Migration 004: Row Level Security Policies
-- Student Status Checkup System
-- =============================================================================
-- Depends on: 001 (tables), 002 (phase2 tables), 003 (functions)
-- =============================================================================
-- Strategy:
--   Admin:   Full access to everything
--   Teacher: Read profiles, manage own classes/assignments, insert attendance/results
--   Parent:  Read own profile, read children's data, send/receive messages
--   System:  SECURITY DEFINER functions bypass RLS for triggers
-- =============================================================================

-- =============================================================================
-- PROFILES
-- =============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Everyone can read profiles (needed for display names, messaging, etc.)
CREATE POLICY "profiles_select_authenticated"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (true);

-- Users can update own profile (limited columns enforced at app level)
-- SECURITY: Users CANNOT change their own role. Use assign_user_role() server-side.
CREATE POLICY "profiles_update_own"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Admin can do everything
CREATE POLICY "profiles_admin_all"
    ON public.profiles FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- =============================================================================
-- ACADEMIC YEARS
-- =============================================================================

ALTER TABLE public.academic_years ENABLE ROW LEVEL SECURITY;

CREATE POLICY "academic_years_select_authenticated"
    ON public.academic_years FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "academic_years_admin_all"
    ON public.academic_years FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- =============================================================================
-- CLASSES
-- =============================================================================

ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;

-- Only show active classes (archived classes hidden from normal queries)
CREATE POLICY "classes_select_authenticated"
    ON public.classes FOR SELECT
    TO authenticated
    USING (is_active = true);

CREATE POLICY "classes_admin_all"
    ON public.classes FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- Teachers can read active classes they are assigned to
CREATE POLICY "classes_teacher_select"
    ON public.classes FOR SELECT
    TO authenticated
    USING (
        public.get_user_role() = 'teacher'
        AND is_active = true
        AND id IN (SELECT public.get_teacher_class_ids())
    );

-- =============================================================================
-- SUBJECTS
-- =============================================================================

ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "subjects_select_authenticated"
    ON public.subjects FOR SELECT
    TO authenticated
    USING (is_active = true);

CREATE POLICY "subjects_admin_all"
    ON public.subjects FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- =============================================================================
-- TEACHERS
-- =============================================================================

ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;

-- Only show active teachers (inactive teachers hidden from normal queries)
CREATE POLICY "teachers_select_authenticated"
    ON public.teachers FOR SELECT
    TO authenticated
    USING (is_active = true);

CREATE POLICY "teachers_admin_all"
    ON public.teachers FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- Teachers can update own teacher record
CREATE POLICY "teachers_update_own"
    ON public.teachers FOR UPDATE
    TO authenticated
    USING (profile_id = auth.uid())
    WITH CHECK (profile_id = auth.uid());

-- =============================================================================
-- STUDENTS
-- =============================================================================

ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

-- Admin: full access
CREATE POLICY "students_admin_all"
    ON public.students FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- Teachers: read students in their assigned classes
CREATE POLICY "students_teacher_select"
    ON public.students FOR SELECT
    TO authenticated
    USING (
        public.get_user_role() = 'teacher'
        AND id IN (SELECT public.get_teacher_student_ids())
    );

-- Parents: read their children
CREATE POLICY "students_parent_select"
    ON public.students FOR SELECT
    TO authenticated
    USING (
        public.get_user_role() = 'parent'
        AND id IN (SELECT public.get_parent_student_ids())
    );

-- =============================================================================
-- TEACHER_ASSIGNMENTS
-- =============================================================================

ALTER TABLE public.teacher_assignments ENABLE ROW LEVEL SECURITY;

-- Admin: full access
CREATE POLICY "teacher_assignments_admin_all"
    ON public.teacher_assignments FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- Teachers: read own assignments
CREATE POLICY "teacher_assignments_teacher_select"
    ON public.teacher_assignments FOR SELECT
    TO authenticated
    USING (
        public.get_user_role() = 'teacher'
        AND teacher_id = public.get_teacher_id()
    );

-- Everyone can read (for reporting, UI display)
CREATE POLICY "teacher_assignments_select_authenticated"
    ON public.teacher_assignments FOR SELECT
    TO authenticated
    USING (true);

-- =============================================================================
-- STUDENT_ENROLLMENTS
-- =============================================================================

ALTER TABLE public.student_enrollments ENABLE ROW LEVEL SECURITY;

-- Admin: full access
CREATE POLICY "student_enrollments_admin_all"
    ON public.student_enrollments FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- Teachers: read enrollments for their assigned classes
CREATE POLICY "student_enrollments_teacher_select"
    ON public.student_enrollments FOR SELECT
    TO authenticated
    USING (
        public.get_user_role() = 'teacher'
        AND class_id IN (SELECT public.get_teacher_class_ids())
    );

-- Parents: read their children's enrollments
CREATE POLICY "student_enrollments_parent_select"
    ON public.student_enrollments FOR SELECT
    TO authenticated
    USING (
        public.get_user_role() = 'parent'
        AND student_id IN (SELECT public.get_parent_student_ids())
    );

-- =============================================================================
-- PARENT_STUDENTS
-- =============================================================================

ALTER TABLE public.parent_students ENABLE ROW LEVEL SECURITY;

-- Admin: full access
CREATE POLICY "parent_students_admin_all"
    ON public.parent_students FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- Parents: read own relationships
CREATE POLICY "parent_students_parent_select"
    ON public.parent_students FOR SELECT
    TO authenticated
    USING (
        public.get_user_role() = 'parent'
        AND parent_id = auth.uid()
    );

-- =============================================================================
-- ATTENDANCE
-- =============================================================================

ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- Admin: full access
CREATE POLICY "attendance_admin_all"
    ON public.attendance FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- Teachers: read attendance for their assigned classes
CREATE POLICY "attendance_teacher_select"
    ON public.attendance FOR SELECT
    TO authenticated
    USING (
        public.get_user_role() = 'teacher'
        AND class_id IN (SELECT public.get_teacher_class_ids())
    );

-- Teachers: insert/update attendance for their assigned classes
CREATE POLICY "attendance_teacher_insert"
    ON public.attendance FOR INSERT
    TO authenticated
    WITH CHECK (
        public.get_user_role() = 'teacher'
        AND marked_by = public.get_teacher_id()
        AND class_id IN (SELECT public.get_teacher_class_ids())
    );

CREATE POLICY "attendance_teacher_update"
    ON public.attendance FOR UPDATE
    TO authenticated
    USING (
        public.get_user_role() = 'teacher'
        AND marked_by = public.get_teacher_id()
        AND class_id IN (SELECT public.get_teacher_class_ids())
    )
    WITH CHECK (
        public.get_user_role() = 'teacher'
        AND marked_by = public.get_teacher_id()
    );

-- Parents: read their children's attendance
CREATE POLICY "attendance_parent_select"
    ON public.attendance FOR SELECT
    TO authenticated
    USING (
        public.get_user_role() = 'parent'
        AND student_id IN (SELECT public.get_parent_student_ids())
    );

-- =============================================================================
-- RESULTS
-- =============================================================================

ALTER TABLE public.results ENABLE ROW LEVEL SECURITY;

-- Admin: full access
CREATE POLICY "results_admin_all"
    ON public.results FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- Teachers: read results for their assignments
CREATE POLICY "results_teacher_select"
    ON public.results FOR SELECT
    TO authenticated
    USING (
        public.get_user_role() = 'teacher'
        AND teacher_assignment_id IN (
            SELECT ta.id FROM public.teacher_assignments ta
            WHERE ta.teacher_id = public.get_teacher_id()
        )
    );

-- Teachers: insert results for their own assignments only
CREATE POLICY "results_teacher_insert"
    ON public.results FOR INSERT
    TO authenticated
    WITH CHECK (
        public.get_user_role() = 'teacher'
        AND teacher_assignment_id IN (
            SELECT ta.id FROM public.teacher_assignments ta
            WHERE ta.teacher_id = public.get_teacher_id()
        )
    );

-- Teachers: update results they created
CREATE POLICY "results_teacher_update"
    ON public.results FOR UPDATE
    TO authenticated
    USING (
        public.get_user_role() = 'teacher'
        AND teacher_assignment_id IN (
            SELECT ta.id FROM public.teacher_assignments ta
            WHERE ta.teacher_id = public.get_teacher_id()
        )
    )
    WITH CHECK (
        public.get_user_role() = 'teacher'
    );

-- Parents: read their children's results
CREATE POLICY "results_parent_select"
    ON public.results FOR SELECT
    TO authenticated
    USING (
        public.get_user_role() = 'parent'
        AND student_id IN (SELECT public.get_parent_student_ids())
    );

-- =============================================================================
-- ACTIVITIES
-- =============================================================================

ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- Everyone reads activities (filtered by class_id if set)
CREATE POLICY "activities_select_authenticated"
    ON public.activities FOR SELECT
    TO authenticated
    USING (
        -- School-wide activities visible to all
        class_id IS NULL
        -- Class-specific: visible to teachers assigned to that class
        OR class_id IN (SELECT public.get_teacher_class_ids())
        -- Class-specific: visible to parents of students in that class
        OR class_id IN (SELECT public.get_parent_class_ids())
        -- Admin sees all
        OR public.get_user_role() = 'administrator'
    );

CREATE POLICY "activities_admin_all"
    ON public.activities FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- Teachers and admins can create activities
CREATE POLICY "activities_teacher_insert"
    ON public.activities FOR INSERT
    TO authenticated
    WITH CHECK (
        public.get_user_role() IN ('administrator', 'teacher')
    );

-- =============================================================================
-- ANNOUNCEMENTS
-- =============================================================================

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- Published announcements visible based on target_audience
CREATE POLICY "announcements_select_published"
    ON public.announcements FOR SELECT
    TO authenticated
    USING (
        is_published = true
        AND (
            target_audience = 'all'
            OR (target_audience = 'teachers' AND public.get_user_role() = 'teacher')
            OR (target_audience = 'parents' AND public.get_user_role() = 'parent')
        )
        -- Class-specific announcements
        AND (
            class_id IS NULL
            OR class_id IN (SELECT public.get_parent_class_ids())
            OR class_id IN (SELECT public.get_teacher_class_ids())
        )
    );

-- Admin sees all (published and drafts)
CREATE POLICY "announcements_admin_all"
    ON public.announcements FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- Admin and teachers can create announcements
CREATE POLICY "announcements_author_insert"
    ON public.announcements FOR INSERT
    TO authenticated
    WITH CHECK (
        public.get_user_role() IN ('administrator', 'teacher')
        AND author_id = auth.uid()
    );

-- Author can update own announcements
CREATE POLICY "announcements_author_update"
    ON public.announcements FOR UPDATE
    TO authenticated
    USING (
        public.get_user_role() = 'administrator'
        OR (author_id = auth.uid())
    )
    WITH CHECK (
        public.get_user_role() = 'administrator'
        OR (author_id = auth.uid())
    );

-- =============================================================================
-- ANNOUNCEMENT_READS
-- =============================================================================

ALTER TABLE public.announcement_reads ENABLE ROW LEVEL SECURITY;

-- Users can read own read receipts
CREATE POLICY "announcement_reads_select_own"
    ON public.announcement_reads FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Admin can read all
CREATE POLICY "announcement_reads_admin_all"
    ON public.announcement_reads FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- Users can mark announcements as read for themselves
CREATE POLICY "announcement_reads_insert_own"
    ON public.announcement_reads FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

-- =============================================================================
-- CONVERSATIONS
-- =============================================================================

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- Users can see conversations they participate in
CREATE POLICY "conversations_participant_select"
    ON public.conversations FOR SELECT
    TO authenticated
    USING (
        participant1_id = auth.uid()
        OR participant2_id = auth.uid()
    );

-- Admin can see all
CREATE POLICY "conversations_admin_all"
    ON public.conversations FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- Users can create conversations with anyone
CREATE POLICY "conversations_authenticated_insert"
    ON public.conversations FOR INSERT
    TO authenticated
    WITH CHECK (
        participant1_id = auth.uid()
        OR participant2_id = auth.uid()
    );

-- =============================================================================
-- MESSAGES
-- =============================================================================

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Conversation participants can read messages
CREATE POLICY "messages_participant_select"
    ON public.messages FOR SELECT
    TO authenticated
    USING (
        conversation_id IN (
            SELECT id FROM public.conversations
            WHERE participant1_id = auth.uid()
               OR participant2_id = auth.uid()
        )
    );

-- Conversation participants can send messages
CREATE POLICY "messages_participant_insert"
    ON public.messages FOR INSERT
    TO authenticated
    WITH CHECK (
        sender_id = auth.uid()
        AND conversation_id IN (
            SELECT id FROM public.conversations
            WHERE participant1_id = auth.uid()
               OR participant2_id = auth.uid()
        )
    );

-- Sender can update own messages (mark read, edit)
CREATE POLICY "messages_sender_update"
    ON public.messages FOR UPDATE
    TO authenticated
    USING (
        -- Sender can update own messages
        sender_id = auth.uid()
        -- Recipient can mark as read
        OR conversation_id IN (
            SELECT id FROM public.conversations
            WHERE participant1_id = auth.uid()
               OR participant2_id = auth.uid()
        )
    )
    WITH CHECK (true);

-- Admin can read all messages
CREATE POLICY "messages_admin_all"
    ON public.messages FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================
-- SECURITY: No INSERT policy for regular users.
-- Notifications are created ONLY via the create_notification() SECURITY DEFINER
-- function, called from edge functions. This prevents clients from spamming notifications.

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users can read own notifications
CREATE POLICY "notifications_select_own"
    ON public.notifications FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Users can update own notifications (mark as read)
CREATE POLICY "notifications_update_own"
    ON public.notifications FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Admin can manage all
CREATE POLICY "notifications_admin_all"
    ON public.notifications FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- NO INSERT POLICY: Only create_notification() SECURITY DEFINER can insert.

-- =============================================================================
-- DEVICE_TOKENS
-- =============================================================================

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

-- Users can manage own device tokens
CREATE POLICY "device_tokens_select_own"
    ON public.device_tokens FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "device_tokens_insert_own"
    ON public.device_tokens FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "device_tokens_update_own"
    ON public.device_tokens FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "device_tokens_delete_own"
    ON public.device_tokens FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());

-- Admin can manage all
CREATE POLICY "device_tokens_admin_all"
    ON public.device_tokens FOR ALL
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- =============================================================================
-- AUDIT_LOGS
-- =============================================================================

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Admin only
CREATE POLICY "audit_logs_admin_select"
    ON public.audit_logs FOR SELECT
    TO authenticated
    USING (public.get_user_role() = 'administrator');

-- Insert is done via SECURITY DEFINER functions only — no direct insert policy
-- This means only edge functions and triggers can write audit logs

-- =============================================================================
-- DONE: RLS policies created.
-- Next: Migration 005 for indexes and seed data.
-- =============================================================================
