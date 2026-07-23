-- =============================================================================
-- SSCS Migration 001: Core Foundation Tables
-- Student Status Checkup System
-- =============================================================================
-- Changes from v1:
--   - Students are records, NOT authenticated users (no profile_id)
--   - Students have first_name / middle_name / last_name
--   - teacher_subjects REPLACED by teacher_assignments (teacher + class + subject + year)
--   - Classes have grade_level and is_active
--   - Profiles have last_login, email_verified, created_by
--   - Teachers have department
--   - Audit columns (created_at, updated_at, created_by) on all tables
-- =============================================================================

-- =============================================================================
-- 1. ENUMS
-- =============================================================================

CREATE TYPE user_role AS ENUM ('administrator', 'teacher', 'parent');
CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
CREATE TYPE enrollment_status AS ENUM ('active', 'transferred', 'withdrawn', 'graduated');
CREATE TYPE relationship_type AS ENUM ('father', 'mother', 'guardian', 'other');

-- =============================================================================
-- 2. PROFILES
-- =============================================================================
-- Every authenticated user (admin, teacher, parent) has exactly one profile.
-- Created automatically via trigger when a user signs up through Supabase Auth.

CREATE TABLE profiles (
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

COMMENT ON TABLE profiles IS 'User profiles linked to Supabase Auth. One per authenticated user.';
COMMENT ON COLUMN profiles.id IS 'Matches auth.users.id — never store a separate user ID.';
COMMENT ON COLUMN profiles.role IS 'administrator, teacher, or parent. Set by edge function only — never by client.';
COMMENT ON COLUMN profiles.is_active IS 'Soft-disable. Disabled users cannot log in but data is preserved.';
COMMENT ON COLUMN profiles.email_verified IS 'Whether the user has confirmed their email.';
COMMENT ON COLUMN profiles.last_login IS 'Timestamp of most recent login. Updated by record_last_login().';
COMMENT ON COLUMN profiles.created_by IS 'Admin who created this user. NULL if self-registered.';

-- =============================================================================
-- 3. ACADEMIC YEARS
-- =============================================================================
-- Defines school years. Only one can be marked is_current at a time.
-- A trigger enforces single-current-year constraint.

CREATE TABLE academic_years (
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

COMMENT ON TABLE academic_years IS 'School years. All time-scoped data references this.';
COMMENT ON COLUMN academic_years.is_current IS 'Only one row can be true. Enforced by trigger.';

CREATE INDEX idx_academic_years_current ON academic_years(is_current) WHERE is_current = true;
CREATE INDEX idx_academic_years_dates ON academic_years(start_date, end_date);

-- =============================================================================
-- 4. CLASSES
-- =============================================================================
-- Year-specific class groups.
-- E.g. grade_level=5, section='A' in academic year '2025-2026'.

CREATE TABLE classes (
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

COMMENT ON TABLE classes IS 'Year-specific class groups. Archived via is_active, never deleted.';
COMMENT ON COLUMN classes.grade_level IS 'Grade number (1-12). Structured data, not extracted from name.';
COMMENT ON COLUMN classes.section IS 'Section letter/label (A, B, etc.)';
COMMENT ON COLUMN classes.capacity IS 'Maximum students. Used for enrollment limits.';
COMMENT ON COLUMN classes.is_active IS 'False for archived classes from past years.';

CREATE INDEX idx_classes_academic_year ON classes(academic_year_id);
CREATE INDEX idx_classes_grade_level ON classes(grade_level);

-- =============================================================================
-- 5. SUBJECTS
-- =============================================================================
-- Academic subjects. Independent and reusable across years.

CREATE TABLE subjects (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT UNIQUE NOT NULL,
    code        TEXT UNIQUE NOT NULL,
    description TEXT,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_by  UUID REFERENCES profiles(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE subjects IS 'Academic subjects. Not year-scoped — reused every year.';
COMMENT ON COLUMN subjects.is_active IS 'False for archived subjects. Never delete — preserve history.';

-- =============================================================================
-- 6. TEACHERS
-- =============================================================================
-- Teacher-specific data. One-to-one with profiles.
-- Teachers ARE authenticated users — they log in to the mobile app.

CREATE TABLE teachers (
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

COMMENT ON TABLE teachers IS 'Teacher records. Links to a profile with role=teacher.';
COMMENT ON COLUMN teachers.employee_id IS 'School-assigned ID (e.g. TCH-001).';
COMMENT ON COLUMN teachers.department IS 'Department name (e.g. Mathematics, Sciences).';
COMMENT ON COLUMN teachers.is_active IS 'False for inactive/deactivated teachers. Never delete — preserve history.';

CREATE INDEX idx_teachers_profile ON teachers(profile_id);
CREATE INDEX idx_teachers_department ON teachers(department);

-- =============================================================================
-- 7. STUDENTS
-- =============================================================================
-- Student records. Students do NOT log in — they are data records only.
-- No profile_id. Students have their own name fields.

CREATE TABLE students (
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

COMMENT ON TABLE students IS 'Student records. NOT authenticated users — data only.';
COMMENT ON COLUMN students.student_id IS 'School-assigned roll number (e.g. STU-001).';
COMMENT ON COLUMN students.emergency_contact IS 'Name of person to contact in emergencies.';
COMMENT ON COLUMN students.emergency_phone IS 'Phone number of emergency contact.';

CREATE INDEX idx_students_name ON students(last_name, first_name);
CREATE INDEX idx_students_student_id ON students(student_id);

-- =============================================================================
-- 8. TEACHER_ASSIGNMENTS
-- =============================================================================
-- Links a teacher to a specific class + subject + academic year.
-- This replaces teacher_subjects and is the source of truth for:
--   - Which students a teacher can manage
--   - Which results a teacher can upload
--   - Which attendance a teacher can record

CREATE TABLE teacher_assignments (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id        UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    class_id          UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    subject_id        UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    academic_year_id  UUID NOT NULL REFERENCES academic_years(id) ON DELETE RESTRICT,
    created_by        UUID REFERENCES profiles(id),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_teacher_assignments UNIQUE (teacher_id, class_id, subject_id, academic_year_id)
);

COMMENT ON TABLE teacher_assignments IS 'Teacher → class → subject assignments per year.';
COMMENT ON COLUMN teacher_assignments.teacher_id IS 'The assigned teacher.';
COMMENT ON COLUMN teacher_assignments.class_id IS 'The class being taught.';
COMMENT ON COLUMN teacher_assignments.subject_id IS 'The subject being taught in this class.';

CREATE INDEX idx_teacher_assignments_teacher ON teacher_assignments(teacher_id);
CREATE INDEX idx_teacher_assignments_class ON teacher_assignments(class_id);
CREATE INDEX idx_teacher_assignments_year ON teacher_assignments(academic_year_id);
CREATE INDEX idx_teacher_assignments_class_subject ON teacher_assignments(class_id, subject_id);

-- =============================================================================
-- 9. STUDENT_ENROLLMENTS
-- =============================================================================
-- Links students to classes. Source of truth for student placement.
-- History is NEVER deleted — status changes instead.

CREATE TABLE student_enrollments (
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

COMMENT ON TABLE student_enrollments IS 'Student-to-class links. History preserved via status.';
COMMENT ON COLUMN student_enrollments.status IS 'active, transferred, withdrawn, or graduated. Never delete — change status.';

CREATE INDEX idx_enrollments_student ON student_enrollments(student_id);
CREATE INDEX idx_enrollments_class ON student_enrollments(class_id);
CREATE INDEX idx_enrollments_status ON student_enrollments(status);

-- =============================================================================
-- 10. PARENT_STUDENTS
-- =============================================================================
-- Many-to-many: a parent can have multiple children, a student can have multiple parents.
-- RLS will enforce that parent_id must reference a profile with role='parent'.

CREATE TABLE parent_students (
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

COMMENT ON TABLE parent_students IS 'Parent-to-student relationships. Supports multiple parents per child.';
COMMENT ON COLUMN parent_students.relationship IS 'father, mother, guardian, or other.';
COMMENT ON COLUMN parent_students.is_primary IS 'Primary contact for notifications. Enforced at app level.';
COMMENT ON COLUMN parent_students.is_active IS 'Soft-delete for custody/family changes.';

CREATE INDEX idx_parent_students_parent ON parent_students(parent_id);
CREATE INDEX idx_parent_students_student ON parent_students(student_id);

-- =============================================================================
-- DONE: Core Foundation tables created.
-- Next: Migration 002 for RLS policies.
-- =============================================================================
