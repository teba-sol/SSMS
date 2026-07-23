-- ============================================================
-- SSCS COMPLETE DATABASE SETUP
-- Run this SINGLE script in Supabase Dashboard > SQL Editor
-- Then create admin user via Authentication > Users > Add User
-- Then run the SEED section at the bottom
-- ============================================================

-- ============================================
-- 1. DROP EVERYTHING (clean slate)
-- ============================================
DROP TRIGGER IF EXISTS trg_messages_update_conversation ON public.messages;
DROP TRIGGER IF EXISTS trg_prevent_delete_current_year ON public.academic_years;
DROP TRIGGER IF EXISTS trg_enforce_single_current_year ON public.academic_years;
DROP TRIGGER IF EXISTS trg_announcements_updated_at ON public.announcements;
DROP TRIGGER IF EXISTS trg_activities_updated_at ON public.activities;
DROP TRIGGER IF EXISTS trg_results_updated_at ON public.results;
DROP TRIGGER IF EXISTS trg_attendance_updated_at ON public.attendance;
DROP TRIGGER IF EXISTS trg_parent_students_updated_at ON public.parent_students;
DROP TRIGGER IF EXISTS trg_student_enrollments_updated_at ON public.student_enrollments;
DROP TRIGGER IF EXISTS trg_students_updated_at ON public.students;
DROP TRIGGER IF EXISTS trg_teachers_updated_at ON public.teachers;
DROP TRIGGER IF EXISTS trg_classes_updated_at ON public.classes;
DROP TRIGGER IF EXISTS trg_academic_years_updated_at ON public.academic_years;
DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;

DROP FUNCTION IF EXISTS public.update_updated_at() CASCADE;
DROP FUNCTION IF EXISTS public.enforce_single_current_year() CASCADE;
DROP FUNCTION IF EXISTS public.prevent_delete_current_year() CASCADE;
DROP FUNCTION IF EXISTS public.set_current_academic_year(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.update_conversation_last_message() CASCADE;
DROP FUNCTION IF EXISTS public.record_last_login(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_teacher_assigned(UUID, UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.get_current_academic_year() CASCADE;
DROP FUNCTION IF EXISTS public.get_user_role() CASCADE;
DROP FUNCTION IF EXISTS public.get_user_id() CASCADE;
DROP FUNCTION IF EXISTS public.get_teacher_id() CASCADE;
DROP FUNCTION IF EXISTS public.get_student_parent_ids(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.assign_user_role(UUID, user_role) CASCADE;
DROP FUNCTION IF EXISTS public.deactivate_user_tokens(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.create_notification(UUID, TEXT, TEXT, TEXT, TEXT, UUID, TEXT) CASCADE;

-- Drop all tables
DROP TABLE IF EXISTS public.audit_logs CASCADE;
DROP TABLE IF EXISTS public.device_tokens CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.conversations CASCADE;
DROP TABLE IF EXISTS public.announcement_reads CASCADE;
DROP TABLE IF EXISTS public.announcements CASCADE;
DROP TABLE IF EXISTS public.activities CASCADE;
DROP TABLE IF EXISTS public.results CASCADE;
DROP TABLE IF EXISTS public.attendance CASCADE;
DROP TABLE IF EXISTS public.parent_students CASCADE;
DROP TABLE IF EXISTS public.student_enrollments CASCADE;
DROP TABLE IF EXISTS public.teacher_assignments CASCADE;
DROP TABLE IF EXISTS public.students CASCADE;
DROP TABLE IF EXISTS public.teachers CASCADE;
DROP TABLE IF EXISTS public.subjects CASCADE;
DROP TABLE IF EXISTS public.classes CASCADE;
DROP TABLE IF EXISTS public.academic_years CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Drop enums
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS gender_type CASCADE;
DROP TYPE IF EXISTS enrollment_status CASCADE;
DROP TYPE IF EXISTS relationship_type CASCADE;
DROP TYPE IF EXISTS attendance_status CASCADE;
DROP TYPE IF EXISTS exam_type CASCADE;
DROP TYPE IF EXISTS announcement_target CASCADE;
DROP TYPE IF EXISTS announcement_priority CASCADE;

SELECT 'Step 1: Cleanup done' as status;

-- ============================================
-- 2. ENUMS
-- ============================================
CREATE TYPE user_role AS ENUM ('administrator', 'teacher', 'parent');
CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
CREATE TYPE enrollment_status AS ENUM ('active', 'transferred', 'withdrawn', 'graduated');
CREATE TYPE relationship_type AS ENUM ('father', 'mother', 'guardian', 'other');
CREATE TYPE attendance_status AS ENUM ('present', 'absent', 'late', 'excused');
CREATE TYPE exam_type AS ENUM ('midterm', 'final', 'quiz', 'assignment', 'project');
CREATE TYPE announcement_target AS ENUM ('all', 'teachers', 'parents');
CREATE TYPE announcement_priority AS ENUM ('low', 'normal', 'high', 'urgent');

-- ============================================
-- 3. TABLES
-- ============================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT UNIQUE,
    avatar_url TEXT,
    role user_role NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    email_verified BOOLEAN NOT NULL DEFAULT false,
    last_login TIMESTAMPTZ,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE academic_years (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN NOT NULL DEFAULT false,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_academic_years_dates CHECK (end_date > start_date)
);

CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    grade_level INTEGER NOT NULL,
    section TEXT,
    capacity INTEGER NOT NULL DEFAULT 40,
    room TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_classes_capacity CHECK (capacity > 0),
    CONSTRAINT chk_classes_grade CHECK (grade_level > 0 AND grade_level <= 12),
    CONSTRAINT uq_classes_year_level_section UNIQUE (academic_year_id, grade_level, section)
);

CREATE TABLE subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    code TEXT UNIQUE NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE teachers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    employee_id TEXT UNIQUE NOT NULL,
    department TEXT,
    qualification TEXT,
    hire_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    middle_name TEXT,
    last_name TEXT NOT NULL,
    date_of_birth DATE NOT NULL,
    gender gender_type,
    address TEXT,
    emergency_contact TEXT,
    emergency_phone TEXT,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE teacher_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE RESTRICT,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_teacher_assignments UNIQUE (teacher_id, class_id, subject_id, academic_year_id)
);

CREATE TABLE student_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE RESTRICT,
    enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status enrollment_status NOT NULL DEFAULT 'active',
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_student_enrollments UNIQUE (student_id, class_id)
);

CREATE TABLE parent_students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    relationship relationship_type NOT NULL DEFAULT 'guardian',
    is_primary BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_parent_students UNIQUE (parent_id, student_id)
);

CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE RESTRICT,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    status attendance_status NOT NULL,
    marked_by UUID NOT NULL REFERENCES teachers(id) ON DELETE RESTRICT,
    notes TEXT,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_attendance_student_class_date UNIQUE (student_id, class_id, date)
);

CREATE TABLE results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    teacher_assignment_id UUID NOT NULL REFERENCES teacher_assignments(id) ON DELETE RESTRICT,
    marks_obtained DECIMAL(5,2),
    total_marks DECIMAL(5,2),
    grade TEXT,
    exam_type exam_type NOT NULL,
    exam_date DATE NOT NULL DEFAULT CURRENT_DATE,
    remarks TEXT,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_results_marks CHECK (
        (marks_obtained IS NULL AND total_marks IS NULL)
        OR (marks_obtained >= 0 AND total_marks > 0 AND marks_obtained <= total_marks)
    )
);

CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    activity_type TEXT NOT NULL,
    activity_date DATE NOT NULL,
    location TEXT,
    organizer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE RESTRICT,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    target_audience announcement_target NOT NULL DEFAULT 'all',
    class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
    priority announcement_priority NOT NULL DEFAULT 'normal',
    is_published BOOLEAN NOT NULL DEFAULT false,
    published_at TIMESTAMPTZ,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE announcement_reads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    announcement_id UUID NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_announcement_reads UNIQUE (announcement_id, user_id)
);

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participant1_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    participant2_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    last_message_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_conversations_participants UNIQUE (participant1_id, participant2_id),
    CONSTRAINT chk_conversations_ordering CHECK (participant1_id < participant2_id)
);

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL,
    reference_type TEXT,
    reference_id UUID,
    action_url TEXT,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    token TEXT UNIQUE NOT NULL,
    platform TEXT NOT NULL,
    device_info TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    logged_out_at TIMESTAMPTZ,
    CONSTRAINT chk_device_tokens_platform CHECK (platform IN ('ios', 'android', 'web'))
);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    action TEXT NOT NULL,
    table_name TEXT,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    success BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

SELECT 'Step 2: Tables created' as status;

-- ============================================
-- 4. FUNCTIONS & TRIGGERS
-- ============================================
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_academic_years_updated_at BEFORE UPDATE ON public.academic_years FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_classes_updated_at BEFORE UPDATE ON public.classes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_teachers_updated_at BEFORE UPDATE ON public.teachers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_students_updated_at BEFORE UPDATE ON public.students FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_student_enrollments_updated_at BEFORE UPDATE ON public.student_enrollments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_parent_students_updated_at BEFORE UPDATE ON public.parent_students FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_attendance_updated_at BEFORE UPDATE ON public.attendance FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_results_updated_at BEFORE UPDATE ON public.results FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_activities_updated_at BEFORE UPDATE ON public.activities FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
CREATE TRIGGER trg_announcements_updated_at BEFORE UPDATE ON public.announcements FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS user_role AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.get_user_id()
RETURNS UUID AS $$
    SELECT auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.get_teacher_id()
RETURNS UUID AS $$
    SELECT t.id FROM public.teachers t WHERE t.profile_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.get_current_academic_year()
RETURNS UUID AS $$
    SELECT id FROM public.academic_years WHERE is_current = true LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_teacher_assigned(p_teacher_id UUID, p_class_id UUID, p_subject_id UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.teacher_assignments
        WHERE teacher_id = p_teacher_id AND class_id = p_class_id AND subject_id = p_subject_id
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.get_student_parent_ids(p_student_id UUID)
RETURNS SETOF UUID AS $$
    SELECT ps.parent_id FROM public.parent_students ps
    WHERE ps.student_id = p_student_id AND ps.is_active = true;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.record_last_login(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.profiles SET last_login = now() WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.assign_user_role(p_user_id UUID, p_role user_role)
RETURNS VOID AS $$
BEGIN
    UPDATE public.profiles SET role = p_role WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.deactivate_user_tokens(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE deactivated_count INTEGER;
BEGIN
    UPDATE public.device_tokens SET is_active = false, logged_out_at = now()
    WHERE user_id = p_user_id AND is_active = true;
    GET DIAGNOSTICS deactivated_count = ROW_COUNT;
    RETURN deactivated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.create_notification(
    p_user_id UUID, p_title TEXT, p_body TEXT, p_type TEXT,
    p_reference_type TEXT DEFAULT NULL, p_reference_id UUID DEFAULT NULL, p_action_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE new_id UUID;
BEGIN
    INSERT INTO public.notifications (user_id, title, body, type, reference_type, reference_id, action_url)
    VALUES (p_user_id, p_title, p_body, p_type, p_reference_type, p_reference_id, p_action_url)
    RETURNING id INTO new_id;
    RETURN new_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.conversations SET last_message_at = NEW.created_at WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_messages_update_conversation
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION public.update_conversation_last_message();

CREATE OR REPLACE FUNCTION public.set_current_academic_year(p_year_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.academic_years SET is_current = false WHERE is_current = true AND id != p_year_id;
    UPDATE public.academic_years SET is_current = true WHERE id = p_year_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.prevent_delete_current_year()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.is_current = true THEN
        RAISE EXCEPTION 'Cannot delete the current academic year.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_delete_current_year
    BEFORE DELETE ON public.academic_years
    FOR EACH ROW EXECUTE FUNCTION public.prevent_delete_current_year();

SELECT 'Step 3: Functions & triggers created' as status;

-- ============================================
-- 5. INDEXES
-- ============================================
CREATE INDEX idx_academic_years_current ON academic_years(is_current) WHERE is_current = true;
CREATE INDEX idx_academic_years_dates ON academic_years(start_date, end_date);
CREATE INDEX idx_classes_academic_year ON classes(academic_year_id);
CREATE INDEX idx_classes_grade_level ON classes(grade_level);
CREATE INDEX idx_teachers_profile ON teachers(profile_id);
CREATE INDEX idx_teachers_department ON teachers(department);
CREATE INDEX idx_students_name ON students(last_name, first_name);
CREATE INDEX idx_students_student_id ON students(student_id);
CREATE INDEX idx_teacher_assignments_teacher ON teacher_assignments(teacher_id);
CREATE INDEX idx_teacher_assignments_class ON teacher_assignments(class_id);
CREATE INDEX idx_teacher_assignments_year ON teacher_assignments(academic_year_id);
CREATE INDEX idx_teacher_assignments_class_subject ON teacher_assignments(class_id, subject_id);
CREATE INDEX idx_enrollments_student ON student_enrollments(student_id);
CREATE INDEX idx_enrollments_class ON student_enrollments(class_id);
CREATE INDEX idx_enrollments_status ON student_enrollments(status);
CREATE INDEX idx_parent_students_parent ON parent_students(parent_id);
CREATE INDEX idx_parent_students_student ON parent_students(student_id);
CREATE INDEX idx_announcements_published ON announcements(is_published, published_at DESC) WHERE is_published = true;
CREATE INDEX idx_announcements_target ON announcements(target_audience, class_id);
CREATE INDEX idx_announcement_reads_user ON announcement_reads(user_id);
CREATE INDEX idx_announcement_reads_announcement ON announcement_reads(announcement_id);
CREATE INDEX idx_conversations_p1 ON conversations(participant1_id);
CREATE INDEX idx_conversations_p2 ON conversations(participant2_id);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at DESC NULLS LAST);
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_unread ON messages(conversation_id, is_read) WHERE is_read = false;
CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);
CREATE INDEX idx_device_tokens_active ON device_tokens(is_active) WHERE is_active = true;
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_table_record ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action, created_at DESC);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);

SELECT 'Step 4: Indexes created' as status;

-- ============================================
-- 6. ROW LEVEL SECURITY
-- ============================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- PROFILES
CREATE POLICY "profiles_select_authenticated" ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY "profiles_admin_all" ON public.profiles FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

-- ACADEMIC YEARS
CREATE POLICY "academic_years_select_authenticated" ON public.academic_years FOR SELECT TO authenticated USING (true);
CREATE POLICY "academic_years_admin_all" ON public.academic_years FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

-- CLASSES
CREATE POLICY "classes_select_authenticated" ON public.classes FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "classes_admin_all" ON public.classes FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

-- SUBJECTS
CREATE POLICY "subjects_select_authenticated" ON public.subjects FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "subjects_admin_all" ON public.subjects FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

-- TEACHERS
CREATE POLICY "teachers_select_authenticated" ON public.teachers FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "teachers_admin_all" ON public.teachers FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');
CREATE POLICY "teachers_update_own" ON public.teachers FOR UPDATE TO authenticated USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

-- STUDENTS
CREATE POLICY "students_admin_all" ON public.students FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');
CREATE POLICY "students_parent_select" ON public.students FOR SELECT TO authenticated USING (
    public.get_user_role() = 'parent' AND id IN (SELECT ps.student_id FROM public.parent_students ps WHERE ps.parent_id = auth.uid() AND ps.is_active = true)
);

-- TEACHER ASSIGNMENTS
CREATE POLICY "teacher_assignments_admin_all" ON public.teacher_assignments FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');
CREATE POLICY "teacher_assignments_select_authenticated" ON public.teacher_assignments FOR SELECT TO authenticated USING (true);

-- STUDENT ENROLLMENTS
CREATE POLICY "student_enrollments_admin_all" ON public.student_enrollments FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');
CREATE POLICY "student_enrollments_parent_select" ON public.student_enrollments FOR SELECT TO authenticated USING (
    public.get_user_role() = 'parent' AND student_id IN (SELECT ps.student_id FROM public.parent_students ps WHERE ps.parent_id = auth.uid() AND ps.is_active = true)
);

-- PARENT STUDENTS
CREATE POLICY "parent_students_admin_all" ON public.parent_students FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');
CREATE POLICY "parent_students_parent_select" ON public.parent_students FOR SELECT TO authenticated USING (public.get_user_role() = 'parent' AND parent_id = auth.uid());

-- ATTENDANCE
CREATE POLICY "attendance_admin_all" ON public.attendance FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

-- RESULTS
CREATE POLICY "results_admin_all" ON public.results FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

-- ACTIVITIES
CREATE POLICY "activities_select_authenticated" ON public.activities FOR SELECT TO authenticated USING (true);
CREATE POLICY "activities_admin_all" ON public.activities FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

-- ANNOUNCEMENTS
CREATE POLICY "announcements_select_published" ON public.announcements FOR SELECT TO authenticated USING (is_published = true OR public.get_user_role() = 'administrator');
CREATE POLICY "announcements_admin_all" ON public.announcements FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

-- ANNOUNCEMENT READS
CREATE POLICY "announcement_reads_select_own" ON public.announcement_reads FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "announcement_reads_admin_all" ON public.announcement_reads FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');
CREATE POLICY "announcement_reads_insert_own" ON public.announcement_reads FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- CONVERSATIONS
CREATE POLICY "conversations_participant_select" ON public.conversations FOR SELECT TO authenticated USING (participant1_id = auth.uid() OR participant2_id = auth.uid());
CREATE POLICY "conversations_admin_all" ON public.conversations FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');
CREATE POLICY "conversations_authenticated_insert" ON public.conversations FOR INSERT TO authenticated WITH CHECK (participant1_id = auth.uid() OR participant2_id = auth.uid());

-- MESSAGES
CREATE POLICY "messages_participant_select" ON public.messages FOR SELECT TO authenticated USING (
    conversation_id IN (SELECT id FROM public.conversations WHERE participant1_id = auth.uid() OR participant2_id = auth.uid())
);
CREATE POLICY "messages_participant_insert" ON public.messages FOR INSERT TO authenticated WITH CHECK (
    sender_id = auth.uid() AND conversation_id IN (SELECT id FROM public.conversations WHERE participant1_id = auth.uid() OR participant2_id = auth.uid())
);
CREATE POLICY "messages_admin_all" ON public.messages FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

-- NOTIFICATIONS
CREATE POLICY "notifications_select_own" ON public.notifications FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "notifications_update_own" ON public.notifications FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "notifications_admin_all" ON public.notifications FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

-- DEVICE TOKENS
CREATE POLICY "device_tokens_select_own" ON public.device_tokens FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "device_tokens_insert_own" ON public.device_tokens FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "device_tokens_update_own" ON public.device_tokens FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "device_tokens_delete_own" ON public.device_tokens FOR DELETE TO authenticated USING (user_id = auth.uid());
CREATE POLICY "device_tokens_admin_all" ON public.device_tokens FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

-- AUDIT LOGS
CREATE POLICY "audit_logs_admin_select" ON public.audit_logs FOR SELECT TO authenticated USING (public.get_user_role() = 'administrator');

SELECT 'Step 5: RLS policies created' as status;
