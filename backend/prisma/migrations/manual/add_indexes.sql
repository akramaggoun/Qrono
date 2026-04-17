-- backend/prisma/migrations/manual/add_partial_unique_qr_index.sql
-- Prisma does not support partial unique indexes in schema.prisma
-- Run this ONCE after npx prisma migrate dev:
--   psql -U qrono -d qrono -f prisma/migrations/manual/add_partial_unique_qr_index.sql

-- Only one active (non-revoked) QR per session at a time
CREATE UNIQUE INDEX IF NOT EXISTS idx_active_qr_per_session
    ON qr_codes (session_id)
    WHERE is_revoked = false;

-- Performance indexes (Prisma does not generate these automatically)
CREATE INDEX IF NOT EXISTS idx_sessions_professor ON sessions(professor_id);
CREATE INDEX IF NOT EXISTS idx_sessions_start     ON sessions(start_time);
CREATE INDEX IF NOT EXISTS idx_attendance_session ON attendance(session_id);
CREATE INDEX IF NOT EXISTS idx_attendance_student ON attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_unauth_occurred    ON unauthorized_access_logs(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, is_read, created_at DESC);
