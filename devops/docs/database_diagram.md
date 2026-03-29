# Qrono — Database Diagram

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                            USERS                                    │
│─────────────────────────────────────────────────────────────────────│
│ id (PK)  · name  · password  · role  · fcm_token  · is_active      │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ 1:1 (via user_id)
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
   ┌────────────┐ ┌──────────────┐ ┌──────────────┐
   │  STUDENTS  │ │  PROFESSORS  │ │    ADMINS    │
   │────────────│ │──────────────│ │──────────────│
   │ id (PK)    │ │ id (PK)      │ │ id (PK)      │
   │ user_id(FK)│ │ user_id (FK) │ │ user_id (FK) │
   │ urn UNIQUE │ │ email UNIQUE │ │ email UNIQUE │
   │ student_cod│ │ professor_cod│ │ created_at   │
   │ group_id   │ │ department   │ └──────────────┘
   └─────┬──────┘ └──────┬───────┘
         │               │
         │ N:1           │ 1:N
         ▼               ▼
   ┌──────────┐    ┌─────────────────────────────────────────┐
   │  GROUPS  │    │                SESSIONS                  │
   │──────────│◄───│─────────────────────────────────────────│
   │ id (PK)  │    │ id (PK)  · course_name                  │
   │ name     │    │ professor_id (FK) → PROFESSORS           │
   │ year_lev │    │ group_id    (FK) → GROUPS               │
   └──────────┘    │ lab_id      (FK) → LABORATORIES         │
                   │ start_time · end_time · is_recurring     │
                   └───────────┬─────────────────────────────┘
                               │ 1:N
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
       ┌────────────┐  ┌────────────┐  ┌────────────────────────┐
       │  QR_CODES  │  │ ATTENDANCE │  │ UNAUTHORIZED_ACCESS    │
       │────────────│  │────────────│  │ _LOGS                  │
       │ id (PK)    │  │ id (PK)    │  │────────────────────────│
       │ session_id │  │ session_id │  │ id (PK)                │
       │ token      │  │ student_id │  │ student_id (FK)        │
       │ valid_from │  │ qr_code_id │  │ session_id (FK)        │
       │ valid_until│  │ recorded_by│  │ lab_id (FK)            │
       │ is_revoked │  │ check_in_at│  │ scanned_token          │
       └────────────┘  │ method     │  │ reason                 │
                       └────────────┘  │ occurred_at            │
                                       └────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         LABORATORIES                                │
│─────────────────────────────────────────────────────────────────────│
│ id (PK)  · name  · building  · room_number  · capacity  · is_active │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         NOTIFICATIONS                               │
│─────────────────────────────────────────────────────────────────────│
│ id (PK)  · user_id (FK → users)  · type  · title  · body  · is_read│
└─────────────────────────────────────────────────────────────────────┘
```

---

## All Tables

### 1. users
Base authentication table. Holds all three roles.

| Column | Type | Notes |
|---|---|---|
| id | uuid | Primary key |
| name | varchar(255) | Full name |
| password | varchar(255) | bcrypt hash — never plain text |
| role | varchar(20) | `admin` \| `professor` \| `student` |
| fcm_token | text | Firebase push token (Phase 2) |
| is_active | boolean | False = account disabled |
| created_at | timestamp | Auto set on insert |
| updated_at | timestamp | Auto updated by trigger |

---

### 2. students
Profile extension for users with role = `student`.

| Column | Type | Notes |
|---|---|---|
| id | uuid | Primary key |
| user_id | uuid | FK → users (UNIQUE, CASCADE) |
| urn | varchar(50) | University Registration Number — used for login, UNIQUE NOT NULL |
| student_code | varchar(50) | Internal code |
| group_id | uuid | FK → groups (SET NULL on delete) |
| created_at | timestamp | Auto set on insert |

---

### 3. professors
Profile extension for users with role = `professor`.

| Column | Type | Notes |
|---|---|---|
| id | uuid | Primary key |
| user_id | uuid | FK → users (UNIQUE, CASCADE) |
| email | varchar(255) | Login email, UNIQUE NOT NULL |
| professor_code | varchar(50) | Internal code |
| department | varchar(100) | Faculty department |
| created_at | timestamp | Auto set on insert |

---

### 4. admins
Profile extension for users with role = `admin`.

| Column | Type | Notes |
|---|---|---|
| id | uuid | Primary key |
| user_id | uuid | FK → users (UNIQUE, CASCADE) |
| email | varchar(255) | Login email, UNIQUE NOT NULL |
| created_at | timestamp | Auto set on insert |

---

### 5. groups
Student cohorts assigned to sessions.

| Column | Type | Notes |
|---|---|---|
| id | uuid | Primary key |
| name | varchar(100) | e.g. `CS-G3` |
| year_level | integer | e.g. `3` |
| created_at | timestamp | Auto set on insert |

---

### 6. laboratories
Physical lab rooms.

| Column | Type | Notes |
|---|---|---|
| id | uuid | Primary key |
| name | varchar(100) | e.g. `Algorithms Lab` |
| building | varchar(100) | e.g. `Building B` |
| room_number | varchar(50) | e.g. `B204` |
| capacity | integer | Max number of students |
| is_active | boolean | False = lab unavailable |
| created_at | timestamp | Auto set on insert |

---

### 7. sessions
Scheduled lab sessions (the timetable).

| Column | Type | Notes |
|---|---|---|
| id | uuid | Primary key |
| course_name | varchar(255) | e.g. `Algorithms & Data Structures` |
| start_time | timestamp | Session start |
| end_time | timestamp | Session end (must be after start) |
| is_recurring | boolean | True = repeating session |
| recurrence | jsonb | e.g. `{"days":["MON","WED"],"until":"2025-06-30"}` |
| professor_id | uuid | FK → professors (NOT NULL, CASCADE) |
| group_id | uuid | FK → groups (NOT NULL, CASCADE) |
| lab_id | uuid | FK → laboratories (NOT NULL, CASCADE) |
| created_at | timestamp | Auto set on insert |

**Constraint:** `end_time > start_time`

---

### 8. qr_codes
QR tokens generated by professors for sessions.

| Column | Type | Notes |
|---|---|---|
| id | uuid | Primary key |
| session_id | uuid | FK → sessions (CASCADE) |
| token | text | Signed JWT string, UNIQUE |
| valid_from | timestamp | When the QR becomes valid |
| valid_until | timestamp | When the QR expires |
| is_revoked | boolean | True = token cancelled |
| created_at | timestamp | Auto set on insert |

**Index:** Only one active (non-revoked) QR per session at a time
(`UNIQUE INDEX WHERE is_revoked = false`)

---

### 9. attendance
Check-in records — one per student per session.

| Column | Type | Notes |
|---|---|---|
| id | uuid | Primary key |
| session_id | uuid | FK → sessions (CASCADE) |
| student_id | uuid | FK → students (CASCADE) |
| qr_code_id | uuid | FK → qr_codes (SET NULL) — null if manual |
| recorded_by_id | uuid | FK → users (SET NULL) — professor if manual |
| check_in_at | timestamp | When student checked in |
| check_out_at | timestamp | When student checked out (nullable) |
| method | varchar(20) | `qr` \| `manual` |
| created_at | timestamp | Auto set on insert |

**Constraint:** `UNIQUE (session_id, student_id)` — one record per student per session

---

### 10. unauthorized_access_logs
Logged every time a QR scan fails validation.

| Column | Type | Notes |
|---|---|---|
| id | uuid | Primary key |
| student_id | uuid | FK → students (SET NULL) |
| session_id | uuid | FK → sessions (SET NULL) |
| lab_id | uuid | FK → laboratories (SET NULL) |
| scanned_token | text | The token that was attempted |
| reason | varchar(50) | `wrong_group` \| `expired` \| `already_used` \| `outside_session_time` \| `invalid_token` |
| occurred_at | timestamp | When the attempt happened |
| professor_notified_at | timestamp | When professor was alerted |
| admin_notified_at | timestamp | When admin was alerted |

---

### 11. notifications
In-app notification feed for all roles.

| Column | Type | Notes |
|---|---|---|
| id | uuid | Primary key |
| user_id | uuid | FK → users (CASCADE) |
| type | varchar(50) | `unauthorized_access` \| `attendance_confirmed` \| `session_reminder` |
| title | varchar(100) | Short notification title |
| body | text | Full notification message |
| data | jsonb | Extra payload (e.g. session id) |
| is_read | boolean | False = unread |
| created_at | timestamp | Auto set on insert |

---

## Key Constraints Summary

| Constraint | Table | Description |
|---|---|---|
| `UNIQUE (session_id, student_id)` | attendance | Student cannot check in twice to the same session |
| `UNIQUE INDEX WHERE is_revoked = false` | qr_codes | Only one active QR per session at a time |
| `CHECK (end_time > start_time)` | sessions | Session must end after it starts |
| `UNIQUE` on urn | students | Each student has one URN |
| `UNIQUE` on email | professors, admins | No duplicate emails |
| `ON DELETE CASCADE` on user_id | students, professors, admins | Deleting a user removes their profile |
| `ON DELETE CASCADE` on session_id | qr_codes, attendance | Deleting a session removes its QR codes and records |

---

## Login Logic

| Role | Login field | Lookup query |
|---|---|---|
| Student | URN | `SELECT u.* FROM users u JOIN students s ON s.user_id = u.id WHERE s.urn = ?` |
| Professor | Email | `SELECT u.* FROM users u JOIN professors p ON p.user_id = u.id WHERE p.email = ?` |
| Admin | Email | `SELECT u.* FROM users u JOIN admins a ON a.user_id = u.id WHERE a.email = ?` |
