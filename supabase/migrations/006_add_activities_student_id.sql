-- =============================================================================
-- SSCS Migration 006: Add student_id to activities
-- Adds optional student-specific logs to the activities table.
-- =============================================================================

ALTER TABLE activities
    ADD COLUMN IF NOT EXISTS student_id UUID REFERENCES students(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_activities_student_id ON activities(student_id);

COMMENT ON COLUMN activities.student_id IS 'Optional: student-specific activity/log. NULL = class/school-wide.';
