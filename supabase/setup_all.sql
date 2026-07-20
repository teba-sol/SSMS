-- =============================================================================
-- SSCS COMPLETE SETUP: All Migrations + Seed Data
-- Run this ENTIRE script in Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- =============================================================================

-- =============================================================================
-- MIGRATION 001: Core Foundation Tables
-- =============================================================================

-- 1. ENUMS
CREATE TYPE user_role AS ENUM ('administrator', 'teacher', 'parent');
CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
CREATE TYPE enrollment_status AS ENUM ('active', 'transferred', 'withdrawn', 'graduated');
CREATE TYPE relationship_type AS ENUM ('father', 'mother', 'guardian', 'other');

-- 2. PROFILES
CREATE TABLE IF NOT EXISTS profiles (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email           TEXT UNIQUE NOT NULL,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    phone           TEXT UNIQUE,
    avatar_url      TEXT,
    role            user_role NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    email_verified  BOOLEAN NOT NULL DEFAULT false,
    last_login      TIMESTAMPTZ,
    created_by      UUID REFERENCES profiles(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. ACADEMIC YEARS
CREATE TABLE IF NOT EXISTS academic_years (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT UNIQUE NOT NULL,
    start_date  DATE NOT NULL,
    end_date    DATE NOT NULL,
    is_current  BOOLEAN NOT NULL DEFAULT false,
    created_by  UUID REFERENCES profiles(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_academic_years_dates CHECK (end_date > start_date)
);

CREATE INDEX IF NOT EXISTS idx_academic_years_current ON academic_years(is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_academic_years_dates ON academic_years(start_date, end_date);

-- 4. CLASSES
CREATE TABLE IF NOT EXISTS classes (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    academic_year_id  UUID NOT NULL REFERENCES academic_years(id) ON DELETE RESTRICT,
    name              TEXT NOT NULL,
    grade_level       INTEGER NOT NULL,
    section           TEXT,
    capacity          INTEGER NOT NULL DEFAULT 40,
    room              TEXT,
    is_active         BOOLEAN NOT NULL DEFAULT true,
    created_by        UUID REFERENCES profiles(id),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_classes_capacity CHECK (capacity > 0),
    CONSTRAINT chk_classes_grade CHECK (grade_level > 0 AND grade_level <= 12),
    CONSTRAINT uq_classes_year_level_section UNIQUE (academic_year_id, grade_level, section)
);

CREATE INDEX IF NOT EXISTS idx_classes_academic_year ON classes(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_classes_grade_level ON classes(grade_level);

-- 5. SUBJECTS
CREATE TABLE IF NOT EXISTS subjects (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT UNIQUE NOT NULL,
    code        TEXT UNIQUE NOT NULL,
    description TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_by  UUID REFERENCES profiles(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. TEACHERS
CREATE TABLE IF NOT EXISTS teachers (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id    UUID UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    employee_id   TEXT UNIQUE NOT NULL,
    department    TEXT,
    qualification TEXT,
    hire_date     DATE,
    is_active     BOOLEAN NOT NULL DEFAULT true,
    created_by    UUID REFERENCES profiles(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_teachers_profile ON teachers(profile_id);
CREATE INDEX IF NOT EXISTS idx_teachers_department ON teachers(department);

-- 7. STUDENTS
CREATE TABLE IF NOT EXISTS students (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id        TEXT UNIQUE NOT NULL,
    first_name        TEXT NOT NULL,
    middle_name       TEXT,
    last_name         TEXT NOT NULL,
    date_of_birth     DATE NOT NULL,
    gender            gender_type,
    address           TEXT,
    emergency_contact TEXT,
    emergency_phone   TEXT,
    created_by        UUID REFERENCES profiles(id),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_students_name ON students(last_name, first_name);
CREATE INDEX IF NOT EXISTS idx_students_student_id ON students(student_id);

-- 8. TEACHER_ASSIGNMENTS
CREATE TABLE IF NOT EXISTS teacher_assignments (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id        UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    class_id          UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    subject_id        UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    academic_year_id  UUID NOT NULL REFERENCES academic_years(id) ON DELETE RESTRICT,
    created_by        UUID REFERENCES profiles(id),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_teacher_assignments UNIQUE (teacher_id, class_id, subject_id, academic_year_id)
);

CREATE INDEX IF NOT EXISTS idx_teacher_assignments_teacher ON teacher_assignments(teacher_id);
CREATE INDEX IF NOT EXISTS idx_teacher_assignments_class ON teacher_assignments(class_id);
CREATE INDEX IF NOT EXISTS idx_teacher_assignments_year ON teacher_assignments(academic_year_id);
CREATE INDEX IF NOT EXISTS idx_teacher_assignments_class_subject ON teacher_assignments(class_id, subject_id);

-- 9. STUDENT_ENROLLMENTS
CREATE TABLE IF NOT EXISTS student_enrollments (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id        UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    class_id          UUID NOT NULL REFERENCES classes(id) ON DELETE RESTRICT,
    enrollment_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    status            enrollment_status NOT NULL DEFAULT 'active',
    created_by        UUID REFERENCES profiles(id),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_student_enrollments UNIQUE (student_id, class_id)
);

CREATE INDEX IF NOT EXISTS idx_enrollments_student ON student_enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_class ON student_enrollments(class_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_status ON student_enrollments(status);

-- 10. PARENT_STUDENTS
CREATE TABLE IF NOT EXISTS parent_students (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    student_id    UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    relationship  relationship_type NOT NULL DEFAULT 'guardian',
    is_primary    BOOLEAN NOT NULL DEFAULT false,
    is_active     BOOLEAN NOT NULL DEFAULT true,
    created_by    UUID REFERENCES profiles(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_parent_students UNIQUE (parent_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_parent_students_parent ON parent_students(parent_id);
CREATE INDEX IF NOT EXISTS idx_parent_students_student ON parent_students(student_id);

-- =============================================================================
-- MIGRATION 002: Operations Tables
-- =============================================================================

CREATE TYPE attendance_status AS ENUM ('present', 'absent', 'late', 'excused');
CREATE TYPE exam_type AS ENUM ('midterm', 'final', 'quiz', 'assignment', 'project');
CREATE TYPE announcement_target AS ENUM ('all', 'teachers', 'parents');
CREATE TYPE announcement_priority AS ENUM ('low', 'normal', 'high', 'urgent');

CREATE TABLE IF NOT EXISTS attendance (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id    UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    class_id      UUID NOT NULL REFERENCES classes(id) ON DELETE RESTRICT,
    date          DATE NOT NULL DEFAULT CURRENT_DATE,
    status        attendance_status NOT NULL,
    marked_by     UUID NOT NULL REFERENCES teachers(id) ON DELETE RESTRICT,
    notes         TEXT,
    created_by    UUID REFERENCES profiles(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_attendance_student_class_date UNIQUE (student_id, class_id, date)
);

CREATE TABLE IF NOT EXISTS results (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id              UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    teacher_assignment_id   UUID NOT NULL REFERENCES teacher_assignments(id) ON DELETE RESTRICT,
    marks_obtained          DECIMAL(5,2),
    total_marks             DECIMAL(5,2),
    grade                   TEXT,
    exam_type               exam_type NOT NULL,
    exam_date               DATE NOT NULL DEFAULT CURRENT_DATE,
    remarks                 TEXT,
    created_by              UUID REFERENCES profiles(id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_results_marks CHECK (
        (marks_obtained IS NULL AND total_marks IS NULL)
        OR (marks_obtained >= 0 AND total_marks > 0 AND marks_obtained <= total_marks)
    )
);

CREATE TABLE IF NOT EXISTS activities (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title             TEXT NOT NULL,
    description       TEXT,
    activity_type     TEXT NOT NULL,
    activity_date     DATE NOT NULL,
    location          TEXT,
    organizer_id      UUID REFERENCES profiles(id) ON DELETE SET NULL,
    class_id          UUID REFERENCES classes(id) ON DELETE SET NULL,
    academic_year_id  UUID NOT NULL REFERENCES academic_years(id) ON DELETE RESTRICT,
    created_by        UUID REFERENCES profiles(id),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS announcements (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title             TEXT NOT NULL,
    content           TEXT NOT NULL,
    author_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    target_audience   announcement_target NOT NULL DEFAULT 'all',
    class_id          UUID REFERENCES classes(id) ON DELETE SET NULL,
    priority          announcement_priority NOT NULL DEFAULT 'normal',
    is_published      BOOLEAN NOT NULL DEFAULT false,
    published_at      TIMESTAMPTZ,
    created_by        UUID REFERENCES profiles(id),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_announcements_published ON announcements(is_published, published_at DESC) WHERE is_published = true;
CREATE INDEX IF NOT EXISTS idx_announcements_target ON announcements(target_audience, class_id);

CREATE TABLE IF NOT EXISTS announcement_reads (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    announcement_id   UUID NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    user_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    read_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_announcement_reads UNIQUE (announcement_id, user_id)
);

CREATE TABLE IF NOT EXISTS conversations (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participant1_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    participant2_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    last_message_at   TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_conversations_participants UNIQUE (participant1_id, participant2_id),
    CONSTRAINT chk_conversations_ordering CHECK (participant1_id < participant2_id)
);

CREATE TABLE IF NOT EXISTS messages (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id   UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content           TEXT NOT NULL,
    is_read           BOOLEAN NOT NULL DEFAULT false,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notifications (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title             TEXT NOT NULL,
    body              TEXT NOT NULL,
    type              TEXT NOT NULL,
    reference_type    TEXT,
    reference_id      UUID,
    action_url        TEXT,
    is_read           BOOLEAN NOT NULL DEFAULT false,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS device_tokens (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    token           TEXT UNIQUE NOT NULL,
    platform        TEXT NOT NULL,
    device_info     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at    TIMESTAMPTZ,
    last_used_at    TIMESTAMPTZ,
    logged_out_at   TIMESTAMPTZ,
    CONSTRAINT chk_device_tokens_platform CHECK (platform IN ('ios', 'android', 'web'))
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID,
    action        TEXT NOT NULL,
    table_name    TEXT,
    record_id     UUID,
    old_values    JSONB,
    new_values    JSONB,
    ip_address    INET,
    user_agent    TEXT,
    success       BOOLEAN NOT NULL DEFAULT true,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- MIGRATION 003: Functions & Triggers
-- =============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_academic_years_updated_at ON public.academic_years;
CREATE TRIGGER trg_academic_years_updated_at BEFORE UPDATE ON public.academic_years FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_classes_updated_at ON public.classes;
CREATE TRIGGER trg_classes_updated_at BEFORE UPDATE ON public.classes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_teachers_updated_at ON public.teachers;
CREATE TRIGGER trg_teachers_updated_at BEFORE UPDATE ON public.teachers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_students_updated_at ON public.students;
CREATE TRIGGER trg_students_updated_at BEFORE UPDATE ON public.students FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_student_enrollments_updated_at ON public.student_enrollments;
CREATE TRIGGER trg_student_enrollments_updated_at BEFORE UPDATE ON public.student_enrollments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_parent_students_updated_at ON public.parent_students;
CREATE TRIGGER trg_parent_students_updated_at BEFORE UPDATE ON public.parent_students FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_attendance_updated_at ON public.attendance;
CREATE TRIGGER trg_attendance_updated_at BEFORE UPDATE ON public.attendance FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_results_updated_at ON public.results;
CREATE TRIGGER trg_results_updated_at BEFORE UPDATE ON public.results FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_activities_updated_at ON public.activities;
CREATE TRIGGER trg_activities_updated_at BEFORE UPDATE ON public.activities FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS trg_announcements_updated_at ON public.announcements;
CREATE TRIGGER trg_announcements_updated_at BEFORE UPDATE ON public.announcements FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE OR REPLACE FUNCTION public.handle_user_email_update()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.email IS DISTINCT FROM NEW.email THEN
        UPDATE public.profiles SET email = NEW.email WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_email_updated ON auth.users;
CREATE TRIGGER on_auth_user_email_updated AFTER UPDATE ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_user_email_update();

CREATE OR REPLACE FUNCTION public.enforce_single_current_year()
RETURNS TRIGGER AS $$
BEGIN
    IF current_setting('app.setting_current_year', true) = 'true' THEN
        RETURN NEW;
    END IF;
    IF TG_OP = 'INSERT' AND NEW.is_current = true THEN
        UPDATE public.academic_years SET is_current = false WHERE id != NEW.id AND is_current = true;
    END IF;
    IF TG_OP = 'UPDATE' AND OLD.is_current IS DISTINCT FROM NEW.is_current THEN
        RAISE EXCEPTION 'Direct UPDATE on is_current is not allowed. Use set_current_academic_year() instead.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_enforce_single_current_year ON public.academic_years;
CREATE TRIGGER trg_enforce_single_current_year BEFORE INSERT OR UPDATE ON public.academic_years FOR EACH ROW EXECUTE FUNCTION public.enforce_single_current_year();

CREATE OR REPLACE FUNCTION public.set_current_academic_year(p_year_id UUID)
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.setting_current_year', 'true', true);
    UPDATE public.academic_years SET is_current = false WHERE is_current = true;
    UPDATE public.academic_years SET is_current = true WHERE id = p_year_id;
    PERFORM set_config('app.setting_current_year', 'false', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.conversations SET last_message_at = NEW.created_at WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_messages_update_conversation ON public.messages;
CREATE TRIGGER trg_messages_update_conversation AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.update_conversation_last_message();

CREATE OR REPLACE FUNCTION public.record_last_login(user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.profiles SET last_login = now() WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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

CREATE OR REPLACE FUNCTION public.prevent_delete_current_year()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.is_current = true THEN
        RAISE EXCEPTION 'Cannot delete the current academic year.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_delete_current_year ON public.academic_years;
CREATE TRIGGER trg_prevent_delete_current_year BEFORE DELETE ON public.academic_years FOR EACH ROW EXECUTE FUNCTION public.prevent_delete_current_year();

-- =============================================================================
-- MIGRATION 004: RLS Policies
-- =============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles_select_authenticated" ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY "profiles_admin_all" ON public.profiles FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.academic_years ENABLE ROW LEVEL SECURITY;
CREATE POLICY "academic_years_select_authenticated" ON public.academic_years FOR SELECT TO authenticated USING (true);
CREATE POLICY "academic_years_admin_all" ON public.academic_years FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "classes_select_authenticated" ON public.classes FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "classes_admin_all" ON public.classes FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "subjects_select_authenticated" ON public.subjects FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "subjects_admin_all" ON public.subjects FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "teachers_select_authenticated" ON public.teachers FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "teachers_admin_all" ON public.teachers FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
CREATE POLICY "students_admin_all" ON public.students FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.teacher_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "teacher_assignments_admin_all" ON public.teacher_assignments FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');
CREATE POLICY "teacher_assignments_select_authenticated" ON public.teacher_assignments FOR SELECT TO authenticated USING (true);

ALTER TABLE public.student_enrollments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "student_enrollments_admin_all" ON public.student_enrollments FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.parent_students ENABLE ROW LEVEL SECURITY;
CREATE POLICY "parent_students_admin_all" ON public.parent_students FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
CREATE POLICY "attendance_admin_all" ON public.attendance FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.results ENABLE ROW LEVEL SECURITY;
CREATE POLICY "results_admin_all" ON public.results FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "activities_admin_all" ON public.activities FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');
CREATE POLICY "activities_select_authenticated" ON public.activities FOR SELECT TO authenticated USING (true);
CREATE POLICY "activities_teacher_insert" ON public.activities FOR INSERT TO authenticated WITH CHECK (public.get_user_role() IN ('administrator', 'teacher'));

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "announcements_admin_all" ON public.announcements FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.announcement_reads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "announcement_reads_admin_all" ON public.announcement_reads FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "conversations_participant_select" ON public.conversations FOR SELECT TO authenticated USING (participant1_id = auth.uid() OR participant2_id = auth.uid());
CREATE POLICY "conversations_admin_all" ON public.conversations FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "messages_admin_all" ON public.messages FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notifications_select_own" ON public.notifications FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "notifications_update_own" ON public.notifications FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "notifications_admin_all" ON public.notifications FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "device_tokens_select_own" ON public.device_tokens FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "device_tokens_insert_own" ON public.device_tokens FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "device_tokens_update_own" ON public.device_tokens FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "device_tokens_admin_all" ON public.device_tokens FOR ALL TO authenticated USING (public.get_user_role() = 'administrator');

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "audit_logs_admin_select" ON public.audit_logs FOR SELECT TO authenticated USING (public.get_user_role() = 'administrator');

-- =============================================================================
-- SEED: Default Admin User
-- =============================================================================

INSERT INTO auth.users (
    instance_id, id, aud, role, email,
    encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated', 'authenticated',
    'admin@sscs.com',
    crypt('Admin@12345', gen_salt('bf')),
    now(),
    '{"provider": "email", "providers": ["email"]}',
    '{"first_name": "System", "last_name": "Administrator", "role": "administrator"}',
    now(), now()
) ON CONFLICT DO NOTHING;

INSERT INTO profiles (id, email, first_name, last_name, role, is_active, email_verified, created_at, updated_at)
SELECT id, 'admin@sscs.com', 'System', 'Administrator', 'administrator'::user_role, true, true, now(), now()
FROM auth.users WHERE email = 'admin@sscs.com'
ON CONFLICT (id) DO NOTHING;

INSERT INTO academic_years (name, start_date, end_date, is_current, created_by, created_at, updated_at)
SELECT '2025-2026', '2025-09-01', '2026-07-31', true, id, now(), now()
FROM auth.users WHERE email = 'admin@sscs.com'
ON CONFLICT (name) DO NOTHING;

INSERT INTO subjects (name, code, description, is_active, created_at)
VALUES
    ('Mathematics', 'MATH', 'Mathematics', true, now()),
    ('English', 'ENG', 'English Language', true, now()),
    ('Science', 'SCI', 'General Science', true, now()),
    ('Social Studies', 'SOC', 'Social Studies', true, now()),
    ('Physical Education', 'PE', 'Physical Education', true, now())
ON CONFLICT (name) DO NOTHING;

-- =============================================================================
-- DONE! Login with: admin@sscs.com / Admin@12345
-- =============================================================================
