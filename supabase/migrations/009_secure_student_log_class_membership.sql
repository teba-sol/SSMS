-- =============================================================================
-- SSCS Migration 009: Bind student logs to active class enrollment
-- Depends on: 007
-- =============================================================================

DROP POLICY IF EXISTS "activities_teacher_insert" ON public.activities;

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
                AND class_id IN (SELECT public.get_teacher_class_ids())
                AND EXISTS (
                    SELECT 1
                    FROM public.student_enrollments enrollment
                    WHERE enrollment.student_id = activities.student_id
                      AND enrollment.class_id = activities.class_id
                      AND enrollment.status = 'active'
                )
            )
        )
    );
