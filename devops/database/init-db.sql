
-- Qrono — Database Schema
-- University Laboratory Access Management System
-- =============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================
-- CORE TABLES (NO DEPENDENCIES)
-- ==============================================

CREATE TABLE users (
    id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        varchar(255) NOT NULL,
    password    varchar(255) NOT NULL,           -- bcrypt hash
    role        varchar(20)  NOT NULL CHECK (role IN ('admin', 'professor', 'student')),
    fcm_token   text,                            -- Firebase push token (Phase 2)
    is_active   boolean   DEFAULT true,
    created_at  timestamp DEFAULT CURRENT_TIMESTAMP,
    updated_at  timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE groups (
    id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        varchar(100) NOT NULL,
    year_level  integer,
    created_at  timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE laboratories (
    id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        varchar(100) NOT NULL,
    building    varchar(100),
    room_number varchar(50),
    capacity    integer,
    is_active   boolean   DEFAULT true,
    created_at  timestamp DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- ROLE PROFILE TABLES
-- ==============================================

CREATE TABLE students (
    id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       uuid UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    urn           varchar(50) UNIQUE NOT NULL,   -- University Registration Number (login)
    student_code  varchar(50),
    group_id      uuid REFERENCES groups(id) ON DELETE SET NULL,
    created_at    timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE professors (
    id              uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         uuid UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    email           varchar(255) UNIQUE NOT NULL,
    professor_code  varchar(50),
    department      varchar(100),
    created_at      timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE admins (
    id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    uuid UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    email      varchar(255) UNIQUE NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- DEPENDENT TABLES
-- ==============================================

CREATE TABLE sessions (
    id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_name  varchar(255) NOT NULL,
    start_time   timestamp NOT NULL,
    end_time     timestamp NOT NULL,
    is_recurring boolean DEFAULT false,
    recurrence   jsonb,
    professor_id uuid NOT NULL REFERENCES professors(id) ON DELETE CASCADE,
    group_id     uuid NOT NULL REFERENCES groups(id)     ON DELETE CASCADE,
    lab_id       uuid NOT NULL REFERENCES laboratories(id) ON DELETE CASCADE,
    created_at   timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_end_after_start CHECK (end_time > start_time)
);

CREATE TABLE qr_codes (
    id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id  uuid NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    token       text UNIQUE NOT NULL,
    valid_from  timestamp NOT NULL,
    valid_until timestamp NOT NULL,
    is_revoked  boolean   DEFAULT false,
    created_at  timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE attendance (
    id             uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id     uuid NOT NULL REFERENCES sessions(id)  ON DELETE CASCADE,
[29-Mar-26 9:55 AM] Akram Aggoun: student_id     uuid NOT NULL REFERENCES students(id)  ON DELETE CASCADE,
    qr_code_id     uuid REFERENCES qr_codes(id)           ON DELETE SET NULL,
    recorded_by_id uuid REFERENCES users(id)              ON DELETE SET NULL,
    check_in_at    timestamp,
    check_out_at   timestamp,
    method         varchar(20) CHECK (method IN ('qr', 'manual')),
    created_at     timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_session_student UNIQUE (session_id, student_id)
);

CREATE TABLE unauthorized_access_logs (
    id                    uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id            uuid REFERENCES students(id)     ON DELETE SET NULL,
    session_id            uuid REFERENCES sessions(id)     ON DELETE SET NULL,
    lab_id                uuid REFERENCES laboratories(id) ON DELETE SET NULL,
    scanned_token         text,
    reason                varchar(50),
    occurred_at           timestamp DEFAULT CURRENT_TIMESTAMP,
    professor_notified_at timestamp,
    admin_notified_at     timestamp
);

CREATE TABLE notifications (
    id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type       varchar(50),
    title      varchar(100),
    body       text,
    data       jsonb,
    is_read    boolean   DEFAULT false,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================
-- INDEXES
-- ==============================================

-- One active (non-revoked) QR per session at a time
CREATE UNIQUE INDEX idx_active_qr_per_session
    ON qr_codes(session_id) WHERE is_revoked = false;

CREATE INDEX idx_sessions_professor ON sessions(professor_id);
CREATE INDEX idx_sessions_start     ON sessions(start_time);
CREATE INDEX idx_attendance_session ON attendance(session_id);
CREATE INDEX idx_attendance_student ON attendance(student_id);
CREATE INDEX idx_unauth_occurred    ON unauthorized_access_logs(occurred_at DESC);
CREATE INDEX idx_notifications_user ON notifications(user_id, is_read, created_at DESC);

-- ==============================================
-- AUTO-UPDATE updated_at ON users
-- ==============================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();