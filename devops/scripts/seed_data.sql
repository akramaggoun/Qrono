-- =============================================================
-- Qrono — Seed Data
-- Demo users and sample data for development and testing
-- Runs automatically after init-db.sql on first docker-compose up
-- Run manually: psql -U qrono -d qrono -f devops/scripts/seed_data.sql
--
-- All demo accounts have password: secret
-- bcrypt hash of "secret" with cost 12 (pre-generated):
-- $2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewdBazeGxqHQtGHu
-- =============================================================

-- ── 1. Users ──────────────────────────────────────────────────────────
INSERT INTO users (id, name, password, role) VALUES

  -- Admin
  ('00000000-0000-0000-0000-000000000001',
   'Admin Qrono',
   '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewdBazeGxqHQtGHu',
   'admin'),

  -- Professor
  ('00000000-0000-0000-0000-000000000002',
   'Dr. Karim Benali',
   '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewdBazeGxqHQtGHu',
   'professor'),

  -- Students
  ('00000000-0000-0000-0000-000000000003',
   'Akram Aggoun',
   '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewdBazeGxqHQtGHu',
   'student'),

  ('00000000-0000-0000-0000-000000000004',
   'Ridha Abderraouf Arrar',
   '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewdBazeGxqHQtGHu',
   'student'),

  ('00000000-0000-0000-0000-000000000005',
   'Khaled Bougouffa',
   '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewdBazeGxqHQtGHu',
   'student');

-- ── 2. Admin profile ──────────────────────────────────────────────────
INSERT INTO admins (id, user_id, email) VALUES
  ('00000000-0000-0000-0001-000000000001',
   '00000000-0000-0000-0000-000000000001',
   'admin@qrono.dz');

-- ── 3. Professor profile ──────────────────────────────────────────────
INSERT INTO professors (id, user_id, email, professor_code, department) VALUES
  ('00000000-0000-0000-0002-000000000001',
   '00000000-0000-0000-0000-000000000002',
   'prof@qrono.dz',
   'PROF-001',
   'Computer Science');

-- ── 4. Group ──────────────────────────────────────────────────────────
INSERT INTO groups (id, name, year_level) VALUES
  ('00000000-0000-0000-0003-000000000001', 'CS-G3', 3);

-- ── 5. Student profiles ───────────────────────────────────────────────
INSERT INTO students (id, user_id, urn, student_code, group_id) VALUES

  ('00000000-0000-0000-0004-000000000001',
   '00000000-0000-0000-0000-000000000003',
   '202312001', 'STU-001',
   '00000000-0000-0000-0003-000000000001'),

  ('00000000-0000-0000-0004-000000000002',
   '00000000-0000-0000-0000-000000000004',
   '202312002', 'STU-002',
   '00000000-0000-0000-0003-000000000001'),

  ('00000000-0000-0000-0004-000000000003',
   '00000000-0000-0000-0000-000000000005',
   '202312003', 'STU-003',
   '00000000-0000-0000-0003-000000000001');

-- ── 6. Laboratory ─────────────────────────────────────────────────────
INSERT INTO laboratories (id, name, building, room_number, capacity) VALUES
  ('00000000-0000-0000-0005-000000000001',
   'Algorithms Lab', 'Building B', 'B204', 30),

  ('00000000-0000-0000-0005-000000000002',
   'Networks Lab', 'Building A', 'A101', 25);

-- ── 7. Session (today 09:00–11:00) ────────────────────────────────────
INSERT INTO sessions (
  id, course_name,
  professor_id, group_id, lab_id,
  start_time, end_time
) VALUES (
  '00000000-0000-0000-0006-000000000001',
  'Algorithms & Data Structures',
  '00000000-0000-0000-0002-000000000001',
  '00000000-0000-0000-0003-000000000001',
  '00000000-0000-0000-0005-000000000001',
  DATE_TRUNC('day', NOW()) + INTERVAL '9 hours',
  DATE_TRUNC('day', NOW()) + INTERVAL '11 hours'
);

-- ── Summary ───────────────────────────────────────────────────────────
DO $$
BEGIN
  RAISE NOTICE '─────────────────────────────────────────────';
  RAISE NOTICE '  Qrono seed data loaded — password: secret';
  RAISE NOTICE '  admin@qrono.dz      → Admin (email login)';
  RAISE NOTICE '  prof@qrono.dz       → Professor (email login)';
  RAISE NOTICE '  URN 202312001       → Akram (URN login)';
  RAISE NOTICE '  URN 202312002       → Ridha (URN login)';
  RAISE NOTICE '  URN 202312003       → Khaled (URN login)';
  RAISE NOTICE '─────────────────────────────────────────────';
END $$;
