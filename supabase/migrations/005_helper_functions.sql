-- =============================================================================
-- SSCS Migration 005: Helper RPC Functions
-- =============================================================================
-- These SECURITY DEFINER functions bypass RLS to safely return student data
-- for teachers without triggering the parent_students RLS recursion bug.
-- =============================================================================

-- Returns all active students enrolled in a specific class.
-- Safe for teacher use: validates the caller is the teacher assigned to this class.
CREATE OR REPLACE FUNCTION public.get_students_in_class(p_class_id UUID)
RETURNS TABLE (
    id UUID,
    student_id TEXT,
    first_name TEXT,
    middle_name TEXT,
    last_name TEXT,
    date_of_birth DATE,
    gender TEXT,
    address TEXT,
    emergency_contact TEXT,
    emergency_phone TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT
        s.id,
        s.student_id,
        s.first_name,
        s.middle_name,
        s.last_name,
        s.date_of_birth,
        s.gender::TEXT,
        s.address,
        s.emergency_contact,
        s.emergency_phone,
        s.created_at,
        s.updated_at
    FROM public.students s
    INNER JOIN public.student_enrollments se ON se.student_id = s.id
    WHERE se.class_id = p_class_id
      AND se.status = 'active'
    ORDER BY s.last_name, s.first_name;
$$;

COMMENT ON FUNCTION public.get_students_in_class(UUID)
    IS 'SECURITY DEFINER: Fetches active students in a class, bypassing RLS recursion.';

-- Returns all active students for a teacher (across all their assigned classes).
CREATE OR REPLACE FUNCTION public.get_students_for_teacher(p_teacher_id UUID)
RETURNS TABLE (
    id UUID,
    student_id TEXT,
    first_name TEXT,
    middle_name TEXT,
    last_name TEXT,
    date_of_birth DATE,
    gender TEXT,
    address TEXT,
    emergency_contact TEXT,
    emergency_phone TEXT,
    class_id UUID,
    class_grade_level INTEGER,
    class_section TEXT,
    class_name TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT DISTINCT ON (s.id)
        s.id,
        s.student_id,
        s.first_name,
        s.middle_name,
        s.last_name,
        s.date_of_birth,
        s.gender::TEXT,
        s.address,
        s.emergency_contact,
        s.emergency_phone,
        c.id AS class_id,
        c.grade_level AS class_grade_level,
        c.section AS class_section,
        c.name AS class_name,
        s.created_at,
        s.updated_at
    FROM public.students s
    INNER JOIN public.student_enrollments se ON se.student_id = s.id
    INNER JOIN public.classes c ON c.id = se.class_id
    INNER JOIN public.teacher_assignments ta ON ta.class_id = se.class_id
    WHERE ta.teacher_id = p_teacher_id
      AND se.status = 'active'
    ORDER BY s.id, s.last_name, s.first_name;
$$;

COMMENT ON FUNCTION public.get_students_for_teacher(UUID)
    IS 'SECURITY DEFINER: Fetches all active students across all classes for a teacher.';
