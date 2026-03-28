<div align="center">

# Qrono

**University Laboratory Access Management System**

QR-code-driven lab access control · Real-time attendance tracking · Unauthorized access detection

[![Backend CI](https://github.com/akramaggoun/Qrono/actions/workflows/main.yml/badge.svg)](https://github.com/akramaggoun/Qrono/actions)
[![Flutter CI](https://github.com/akramaggoun/Qrono/actions/workflows/main.yml/badge.svg)](https://github.com/akramaggoun/Qrono/actions)

</div>

---

## What is Qrono?

Qrono is a mobile application that manages access to university laboratories. Professors generate a QR code for each lab session. Students scan it to check in. The system records attendance automatically, detects unauthorized access in real time, and notifies professors and administrators instantly.

---

## Features

- **QR-based attendance** — professor generates a QR code per session, student scans it to check in
- **Role-based access** — three roles with different permissions: admin, professor, student
- **Unauthorized access detection** — invalid scans are logged and reported immediately
- **Real-time monitoring** — live lab occupancy and alert feed (Phase 2)
- **Manual attendance** — professor can mark students present without a QR scan
- **Push notifications** — FCM-based alerts for professors and admins (Phase 2)
- **Session scheduling** — full timetable management with group and lab assignment

---

## Tech stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter 3.x (Android + iOS) |
| API server | Node.js 20 LTS + Express 4 |
| Database | PostgreSQL 16 |
| Real-time | Socket.io 4 (Phase 2) |
| Cache | Redis 7 (Phase 2) |
| Process manager | PM2 |
| Reverse proxy | Nginx |
| Containers | Docker + Docker Compose |
| CI/CD | GitHub Actions |

---

## Team

| Member | Role | Domain |
|---|---|---|
| Akram Aggoun | Student 1 — DevOps / DB | Database, Docker, CI/CD, deployment |
| Ridha Abderraouf Arrar | Student 2 — Backend | Authentication, API, QR logic |
| Khaled Bougouffa | Student 3 — Frontend | Flutter mobile app, UI |

---

## Project structure

```
Qrono/
├── backend/                    # Node.js + Express API (Ridha)
│   ├── src/
│   │   ├── controllers/        # auth.controller.js, attendance.controller.js
│   │   ├── models/             # User.js, Session.js, Attendance.js
│   │   ├── routes/             # auth.routes.js, attendance.routes.js
│   │   ├── services/           # qr.service.js
│   │   ├── middlewares/        # auth.middleware.js
│   │   └── server.js
│   ├── tests/
│   │   └── integration/        # Jest + Supertest integration tests
│   ├── .env.example
│   ├── Dockerfile
│   └── package.json
│
├── frontend/                   # Flutter mobile application (Khaled)
│   └── lib/
│       ├── models/             # user.dart, attendance_record.dart
│       ├── screens/            # login_screen.dart, dashboard_screen.dart, scanner_screen.dart
│       ├── widgets/            # custom_button.dart, attendance_card.dart
│       ├── services/           # api_service.dart
│       ├── providers/          # auth_provider.dart
│       └── main.dart
│
├── devops/                     # Akram — infrastructure and database
│   ├── database/
│   │   └── init-db.sql         # Complete PostgreSQL schema (10 tables)
│   ├── scripts/
│   │   ├── seed_data.sql       # Demo users and sample data
│   │   ├── deploy.sh           # Production deployment script
│   │   └── run_tests.sh        # Test automation script
│   ├── nginx/
│   │   └── default.conf        # Nginx reverse proxy config
│   └── docs/
│       ├── api_spec.md         # Full API documentation
│       └── database_diagram.md # ER diagram and table reference
│
├── .github/
│   └── workflows/
│       └── main.yml            # CI/CD pipeline
│
├── docker-compose.yml          # PostgreSQL + Node.js + PgAdmin
├── .env.example                # Environment variable template
├── .gitignore
└── README.md
```

---

## Getting started

### Prerequisites

Install the following on your machine:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/Mac) or Docker + Docker Compose (Linux)
- [Flutter 3.x](https://docs.flutter.dev/get-started/install)
- [Git](https://git-scm.com/)

### 1. Clone the repository

```bash
git clone https://github.com/akramaggoun/Qrono.git
cd Qrono
```

### 2. Set up environment variables

```bash
cp .env.example .env
```

Open `.env` and set `POSTGRES_PASSWORD` and `JWT_SECRET` to anything you like for local development. Leave everything else as-is.

### 3. Start the database and backend

```bash
docker-compose up -d
```

This command:
- Starts PostgreSQL on port **5432**
- Creates all 10 database tables automatically (runs `devops/database/init-db.sql`)
- Loads demo users and sample data (runs `devops/scripts/seed_data.sql`)
- Starts the Node.js API on port **3000**
- Starts PgAdmin on port **5050**

Wait about 10 seconds, then verify:

```bash
curl http://localhost:3000/api/health
# Expected: {"status":"healthy","checks":{"database":"ok"}}
```

### 4. Start the Flutter app

```bash
cd frontend
flutter pub get
flutter run
```

> On Android emulator, the app connects to `http://10.0.2.2:3000/api` — this is how the emulator reaches your machine's localhost. On a real device, update the base URL in `lib/services/api_service.dart` to your machine's local IP.

### 5. Open PgAdmin (optional — to inspect the database)

Open [http://localhost:5050](http://localhost:5050) in your browser.

- Email: `admin@qrono.dz`
- Password: `admin`

Connect to the server using host `db`, port `5432`, username and password from your `.env`.

---

## Demo credentials

All demo accounts have the password: **`secret`**

| Role | Login field | Value |
|---|---|---|
| Admin | Email | `admin@qrono.dz` |
| Professor | Email | `prof@qrono.dz` |
| Student 1 | URN | `202312001` |
| Student 2 | URN | `202312002` |
| Student 3 | URN | `202312003` |

> Students log in with their **URN** (University Registration Number).
> Professors and admins log in with their **email**.

---

## Database schema

The database has 10 tables. The `users` table is the single auth table shared by all three roles. Admin lives entirely in `users` — no separate profile table is needed.

### Role breakdown

| Role | Table(s) | Login field | Extra profile |
|---|---|---|---|
| `admin` | `users` only | Email | None — `users` is enough |
| `professor` | `users` + `professors` | Email | `professor_code`, `department` |
| `student` | `users` + `students` | URN | `student_code`, `urn`, `group_id` |

### Table relationships

```
users  (role = 'admin' | 'professor' | 'student')
  │
  ├── [role = admin]
  │     No extra table. Admin manages everything
  │     through the API using their user id.
  │     Receives notifications via notifications table.
  │
  ├── [role = professor]  →  professors (1:1 via user_id)
  │     Adds: professor_code, department
  │     professors ──────────────────────────── sessions (1:N)
  │
  ├── [role = student]    →  students   (1:1 via user_id)
  │     Adds: student_code, urn, group_id
  │     students ────────────────────────────── attendance (1:N)
  │
  └── notifications (1:N via user_id)
        All three roles receive notifications here.

groups
  ├── students        (1:N — a group contains many students)
  └── sessions        (1:N — a group is assigned to many sessions)

laboratories
  └── sessions        (1:N — a lab hosts many sessions)

sessions
  ├── qr_codes        (1:N — one active QR per session at a time)
  ├── attendance      (1:N — one record per student per session)
  └── unauthorized_access_logs (1:N — failed scan attempts)

qr_codes
  └── attendance      (1:N — which QR was used for check-in)

students
  └── unauthorized_access_logs (1:N — who triggered the alert)

laboratories
  └── unauthorized_access_logs (1:N — where the alert occurred)
```

### Key constraints

- `attendance(session_id, student_id)` — **UNIQUE** — a student cannot check in twice to the same session
- `qr_codes(session_id) WHERE is_revoked = FALSE` — **UNIQUE** — only one active QR per session at a time
- `sessions` — `end_time > start_time` check constraint
- `users.email` — **UNIQUE** — no two accounts share the same email
- `students.urn` — **UNIQUE** — each student has one University Registration Number

### All 10 tables

| # | Table | Purpose |
|---|---|---|
| 1 | `users` | Base auth for all roles — **admin lives here** |
| 2 | `students` | Student profile (extends `users`) |
| 3 | `professors` | Professor profile (extends `users`) |
| 4 | `groups` | Student cohorts e.g. CS-G3 |
| 5 | `laboratories` | Physical lab rooms |
| 6 | `sessions` | Scheduled lab sessions (timetable) |
| 7 | `qr_codes` | Generated QR tokens per session |
| 8 | `attendance` | Check-in records (QR or manual) |
| 9 | `unauthorized_access_logs` | Failed / invalid scan attempts |
| 10 | `notifications` | In-app notification feed (all roles) |

Full schema: [`devops/database/init-db.sql`](devops/database/init-db.sql)
Full ER diagram: [`devops/docs/database_diagram.md`](devops/docs/database_diagram.md)

---

## API overview

Base URL: `http://localhost:3000/api`

All endpoints except `/auth/login` require: `Authorization: Bearer <token>`

| Method | Endpoint | Who | Description |
|---|---|---|---|
| POST | `/auth/login` | PUBLIC | Login — students use URN, others use email |
| GET | `/auth/me` | ALL | Get own profile |
| POST | `/attendance/sessions` | PROFESSOR | Create a lab session |
| GET | `/attendance/sessions` | ALL | List sessions (filtered by role) |
| POST | `/attendance/qr/generate` | PROFESSOR | Generate QR code for a session |
| POST | `/attendance/scan` | STUDENT | Scan QR code — records attendance |
| POST | `/attendance/manual` | PROFESSOR | Manual check-in without QR |
| GET | `/attendance/session/:id` | PROF / ADMIN | View attendance for a session |
| GET | `/attendance/student/:id` | STUDENT / ADMIN | View student's attendance history |
| GET | `/api/health` | PUBLIC | Server and database health check |

Full API documentation: [`devops/docs/api_spec.md`](devops/docs/api_spec.md)

---

## Demo scenario

The teacher's 6-step demo scenario that the system must support:

```
1. Professor logs in → POST /auth/login (email + password)
2. Professor creates a session → POST /attendance/sessions
3. System generates a QR code → POST /attendance/qr/generate
4. Student logs in → POST /auth/login (URN + password)
5. Student scans the QR code → POST /attendance/scan
6. Professor views attendance → GET /attendance/session/:id
```

---

## Branch strategy

```
main          ← production only (requires 2 approvals + CI passing)
└── develop   ← integration branch (requires 1 approval + CI passing)
    ├── feature/aa/{name}    ← Akram Aggoun (Student 1 — DevOps / DB)
    ├── feature/raa/{name}   ← Ridha Abderraouf Arrar (Student 2 — Backend)
    └── feature/kb/{name}    ← Khaled Bougouffa (Student 3 — Frontend)
```

**Rules:**
- Never push directly to `main` or `develop`
- Always open a Pull Request — even for small changes
- CI must pass before any merge is allowed
- `develop → main` requires all three members to approve

---

## Running tests

```bash
cd backend

# Run all integration tests
npm test

# Run with coverage report
npm run test:coverage
```

Or using the automation script (handles Docker mode too):

```bash
# Local
bash devops/scripts/run_tests.sh

# Inside Docker containers
bash devops/scripts/run_tests.sh --docker
```

---

## CI/CD pipeline

Every push to any `feature/*` branch automatically triggers:

1. **Backend CI** — ESLint + applies database schema + runs Jest tests
2. **Flutter CI** — `flutter analyze` + `flutter test` + debug APK build

Every merge to `main` additionally triggers:

3. **Deploy** — SSH into the server and run `devops/scripts/deploy.sh`

Pipeline file: [`.github/workflows/main.yml`](.github/workflows/main.yml)

---

## Environment variables

Copy `.env.example` to `.env` and fill in your values.

| Variable | Required | Description |
|---|---|---|
| `POSTGRES_DB` | Yes | Database name (default: `qrono`) |
| `POSTGRES_USER` | Yes | Database user |
| `POSTGRES_PASSWORD` | Yes | Database password |
| `DATABASE_URL` | Yes | Full PostgreSQL connection string |
| `JWT_SECRET` | Yes | Secret for signing JWT tokens |
| `PORT` | No | API port (default: `3000`) |
| `REDIS_URL` | Phase 2 | Redis connection string |
| `FIREBASE_CREDENTIALS` | Phase 2 | Path to Firebase service account JSON |

Generate a strong `JWT_SECRET`:
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

---

## Development phases

### Phase 1 — MVP (current focus)

- [x] Database schema (10 tables)
- [ ] Authentication — URN login for students, email login for professors and admins
- [ ] Session management — create, list, view sessions
- [ ] QR code generation and scanning
- [ ] Attendance recording (QR + manual)
- [ ] Attendance history view

### Phase 2 — Improvements (after MVP works)

- [ ] Unauthorized access alerts (real-time via Socket.io)
- [ ] Push notifications (Firebase FCM)
- [ ] Live lab occupancy dashboard
- [ ] Redis — QR replay attack prevention, JWT blacklist
- [ ] Attendance statistics and charts
- [ ] Enhanced security and input validation

---

## Common commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View backend logs
docker-compose logs -f backend

# Reset the database (deletes all data)
docker-compose down -v && docker-compose up -d

# Open a psql shell
docker-compose exec db psql -U qrono -d qrono

# Rebuild the backend image after dependency changes
docker-compose up -d --build backend
```

---

## License

University project — Université des Sciences et de la Technologie.
