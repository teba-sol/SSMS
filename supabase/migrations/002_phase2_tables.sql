-- =============================================================================
-- SSCS Migration 002: Operations Tables (Phase 2)
-- Student Status Checkup System
-- =============================================================================
-- Tables: attendance, results, activities, announcements, announcement_reads,
--         conversations, messages, notifications, device_tokens, audit_logs
-- =============================================================================
-- Depends on Phase 1 tables: profiles, students, teachers, classes,
--   academic_years, subjects, teacher_assignments, student_enrollments
-- =============================================================================

-- =============================================================================
-- 1. ENUMS
-- =============================================================================

CREATE TYPE attendance_status AS ENUM ('present', 'absent', 'late', 'excused');
CREATE TYPE exam_type AS ENUM ('midterm', 'final', 'quiz', 'assignment', 'project');
CREATE TYPE announcement_target AS ENUM ('all', 'teachers', 'parents');
CREATE TYPE announcement_priority AS ENUM ('low', 'normal', 'high', 'urgent');

-- =============================================================================
-- 2. ATTENDANCE
-- =============================================================================
-- One record per student per class per day.
-- Teachers can only mark attendance for classes they are assigned to.

CREATE TABLE attendance (
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

COMMENT ON TABLE attendance IS 'Daily attendance records. One row per student per class per day.';
COMMENT ON COLUMN attendance.marked_by IS 'Teacher who recorded this. Must be assigned to this class via teacher_assignments.';
COMMENT ON COLUMN attendance.status IS 'present, absent, late, or excused.';
COMMENT ON COLUMN attendance.notes IS 'Reason for absence/lateness when applicable.';

-- =============================================================================
-- 3. RESULTS
-- =============================================================================
-- Teachers upload grades for students in their assigned classes.
-- teacher_assignment_id links to teacher + class + subject + year in one join.

CREATE TABLE results (
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

COMMENT ON TABLE results IS 'Student grades. Multiple per student (quizzes, midterms, finals).';
COMMENT ON COLUMN results.teacher_assignment_id IS 'Links to teacher+class+subject+year. Use to verify upload authorization.';
COMMENT ON COLUMN results.marks_obtained IS 'Raw score. NULL if grade-only system.';
COMMENT ON COLUMN results.total_marks IS 'Maximum possible marks. NULL if grade-only system.';
COMMENT ON COLUMN results.grade IS 'Letter grade (A, B+, etc.). Nullable if system uses marks only.';

-- =============================================================================
-- 4. ACTIVITIES
-- =============================================================================
-- Extracurricular activities, events, field trips.
-- class_id is NULL for school-wide activities.

CREATE TABLE activities (
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

COMMENT ON TABLE activities IS 'Extracurricular activities and events.';
COMMENT ON COLUMN activities.class_id IS 'NULL = school-wide. Set = class-specific activity.';
COMMENT ON COLUMN activities.organizer_id IS 'User who organized this activity.';
COMMENT ON COLUMN activities.activity_type IS 'sports, club, event, field_trip, competition, etc.';
COMMENT ON COLUMN activities.academic_year_id IS 'Stored directly — activities are queried by year, not by class.';

-- =============================================================================
-- 5. ANNOUNCEMENTS
-- =============================================================================
-- School-wide or targeted announcements. Stored once, read status tracked separately.

CREATE TABLE announcements (
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

COMMENT ON TABLE announcements IS 'Announcements. Targeted by role and optionally by class.';
COMMENT ON COLUMN announcements.target_audience IS 'all, teachers, or parents. No student-facing app.';
COMMENT ON COLUMN announcements.class_id IS 'NULL = not class-specific. Set = only that class sees it.';
COMMENT ON COLUMN announcements.is_published IS 'false = draft. true = visible to target audience.';

CREATE INDEX idx_announcements_published ON announcements(is_published, published_at DESC) WHERE is_published = true;
CREATE INDEX idx_announcements_target ON announcements(target_audience, class_id);

-- =============================================================================
-- 6. ANNOUNCEMENT_READS
-- =============================================================================
-- Tracks which users have read which announcements.

CREATE TABLE announcement_reads (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    announcement_id   UUID NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    user_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    read_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_announcement_reads UNIQUE (announcement_id, user_id)
);

COMMENT ON TABLE announcement_reads IS 'Read status per user per announcement.';

CREATE INDEX idx_announcement_reads_user ON announcement_reads(user_id);
CREATE INDEX idx_announcement_reads_announcement ON announcement_reads(announcement_id);

-- =============================================================================
-- 7. CONVERSATIONS
-- =============================================================================
-- 1:1 direct message threads between two users.
-- Canonical ordering: participant1_id < participant2_id prevents duplicate pairs.

CREATE TABLE conversations (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participant1_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    participant2_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    last_message_at   TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_conversations_participants UNIQUE (participant1_id, participant2_id),
    CONSTRAINT chk_conversations_ordering CHECK (participant1_id < participant2_id)
);

COMMENT ON TABLE conversations IS 'Direct message threads. One per user pair, canonical ordering enforced.';
COMMENT ON COLUMN conversations.participant1_id IS 'First participant. Always the lower UUID.';
COMMENT ON COLUMN conversations.participant2_id IS 'Second participant. Always the higher UUID.';
COMMENT ON COLUMN conversations.last_message_at IS 'Timestamp of most recent message. Updated by app.';

CREATE INDEX idx_conversations_p1 ON conversations(participant1_id);
CREATE INDEX idx_conversations_p2 ON conversations(participant2_id);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at DESC NULLS LAST);

-- =============================================================================
-- 8. MESSAGES
-- =============================================================================
-- Individual messages within a conversation.

CREATE TABLE messages (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id   UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content           TEXT NOT NULL,
    is_read           BOOLEAN NOT NULL DEFAULT false,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE messages IS 'Chat messages. Realtime via Supabase.';
COMMENT ON COLUMN messages.is_read IS 'false = unread. Unread counter = COUNT where is_read=false and sender_id != current_user.';

CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_unread ON messages(conversation_id, is_read) WHERE is_read = false;

-- =============================================================================
-- 9. NOTIFICATIONS
-- =============================================================================
-- System notifications (attendance alerts, results posted, announcements).
-- NOT chat messages — those live in the messages table.

CREATE TABLE notifications (
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

COMMENT ON TABLE notifications IS 'System notifications. NOT chat messages.';
COMMENT ON COLUMN notifications.type IS 'attendance, result, announcement, enrollment, system, etc.';
COMMENT ON COLUMN notifications.reference_type IS 'Polymorphic: which table this notification refers to.';
COMMENT ON COLUMN notifications.reference_id IS 'Polymorphic: which record this notification refers to.';
COMMENT ON COLUMN notifications.action_url IS 'Deep-link route the app navigates to when notification is tapped.';
COMMENT ON COLUMN notifications.is_read IS 'false = unread. App shows badge count.';

CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;

-- =============================================================================
-- 10. DEVICE_TOKENS
-- =============================================================================
-- Firebase FCM tokens for push notifications. Multiple devices per user.

CREATE TABLE device_tokens (
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

COMMENT ON TABLE device_tokens IS 'FCM device tokens for push notifications.';
COMMENT ON COLUMN device_tokens.platform IS 'ios, android, or web.';
COMMENT ON COLUMN device_tokens.is_active IS 'false = deactivated. Set on logout via deactivate_user_tokens().';
COMMENT ON COLUMN device_tokens.last_seen_at IS 'Last time this device was active (periodic ping).';
COMMENT ON COLUMN device_tokens.last_used_at IS 'Last time this token was used for push delivery.';
COMMENT ON COLUMN device_tokens.logged_out_at IS 'Set when user logs out. Useful for debugging.';

CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);
CREATE INDEX idx_device_tokens_active ON device_tokens(is_active) WHERE is_active = true;

-- =============================================================================
-- 11. AUDIT_LOGS
-- =============================================================================
-- Immutable record of important actions.
-- NO foreign key on user_id — audit logs survive user deletion.

CREATE TABLE audit_logs (
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

COMMENT ON TABLE audit_logs IS 'Immutable audit trail. No FK on user_id — logs survive user deletion.';
COMMENT ON COLUMN audit_logs.user_id IS 'Who performed the action. NULL for system-triggered actions.';
COMMENT ON COLUMN audit_logs.action IS 'create, update, delete, login, logout, export, etc.';
COMMENT ON COLUMN audit_logs.old_values IS 'JSON snapshot of record before change.';
COMMENT ON COLUMN audit_logs.new_values IS 'JSON snapshot of record after change.';
COMMENT ON COLUMN audit_logs.ip_address IS 'INET type for efficient storage and IPv4/IPv6 support.';
COMMENT ON COLUMN audit_logs.success IS 'Whether the action completed successfully. false = failed attempt.';

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_table_record ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action, created_at DESC);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);

-- =============================================================================
-- DONE: Phase 2 Operations tables created.
-- Next: Migration 003 for trigger functions, then 004 for RLS policies.
-- =============================================================================
