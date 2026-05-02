# Qrono — API Specification

**Base URL:** `http://localhost:3000/api`
**Auth:** All endpoints except `/auth/login` require `Authorization: Bearer <token>`

---

## Authentication

### POST /auth/login
Login for all roles. Students send URN, professors and admins send email.

**No auth required.**

**Student request:**
```json
{ "urn": "202312001", "password": "secret" }
```

**Professor / Admin request:**
```json
{ "email": "prof@qrono.dz", "password": "secret" }
```

**Success — 200:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id":       "uuid",
    "name":     "Akram Aggoun",
    "role":     "student"
  }
}
```

**Errors:**
- `401` — wrong URN/email or wrong password
- `401` — account is deactivated (`is_active = false`)
- `422` — missing required fields

---

### GET /auth/me
Returns the profile of the currently logged-in user.

**Success — 200:**
```json
{
  "id":        "uuid",
  "name":      "Akram Aggoun",
  "role":      "student",
  "isActive":  true,
  "createdAt": "2025-04-10T09:00:00Z"
}
```

**Error:** `401` — missing or invalid token

---

### POST /auth/logout
Invalidates the current session.

**Success — 200:**
```json
{ "message": "Logged out successfully" }
```

---

## Sessions

### GET /attendance/sessions
Returns sessions based on the caller's role:
- **Professor** → only their own sessions
- **Student** → only sessions for their group
- **Admin** → all sessions

**Query parameters (optional):**
```
?date=2025-04-10    filter by date (YYYY-MM-DD)
?labId=uuid         filter by laboratory
```

**Success — 200:**
```json
[
  {
    "id":          "uuid",
    "courseName":  "Algorithms & Data Structures",
    "startTime":   "2025-04-10T09:00:00Z",
    "endTime":     "2025-04-10T11:00:00Z",
    "professor":   { "id": "uuid", "name": "Dr. Karim Benali" },
    "group":       { "id": "uuid", "name": "CS-G3" },
    "lab":         { "id": "uuid", "name": "Algorithms Lab", "roomNumber": "B204" }
  }
]
```

---

### POST /attendance/sessions
Create a new session. **Professor or Admin only.**

**Request body:**
```json
{
  "courseName": "Algorithms & Data Structures",
  "groupId":    "uuid",
  "labId":      "uuid",
  "startTime":  "2025-04-10T09:00:00Z",
  "endTime":    "2025-04-10T11:00:00Z"
}
```

**Success — 201:**
```json
{
  "id":         "uuid",
  "courseName": "Algorithms & Data Structures",
  "startTime":  "2025-04-10T09:00:00Z",
  "endTime":    "2025-04-10T11:00:00Z"
}
```

**Errors:**
- `403` — caller is not a professor or admin
- `422` — missing required fields or endTime before startTime

---

### GET /attendance/sessions/:id
Get a single session by ID.

**Success — 200:** same shape as the list item above.

**Error:** `404` — session not found

---

## QR Code

### POST /attendance/qr/generate
Generate a QR code for a session. **Professor only.**

**Request body:**
```json
{
  "sessionId":       "uuid",
  "validityMinutes": 90
}
```

**Success — 201:**
```json
{
  "qrCodeId":   "uuid",
  "token":      "eyJhbGciOiJIUzI1NiIs...",
  "validFrom":  "2025-04-10T09:00:00Z",
  "validUntil": "2025-04-10T10:30:00Z"
}
```

> The `token` value is what gets encoded into the QR image by the Flutter app using `qr_flutter`.
> Generating a new QR automatically revokes the previous one for the same session.

**Errors:**
- `403` — caller is not the professor of this session
- `404` — session not found

---

### DELETE /attendance/qr/:id/revoke
Revoke an active QR code early. **Professor only.**

**Success — 200:**
```json
{ "message": "QR code revoked" }
```

---

## Attendance

### POST /attendance/scan
Student scans a QR code. **Student only.**

**Request body:**
```json
{ "token": "eyJhbGciOiJIUzI1NiIs..." }
```

**Success — 201:**
```json
{
  "attendanceId": "uuid",
  "sessionId":    "uuid",
  "checkInAt":    "2025-04-10T09:05:00Z",
  "method":       "qr"
}
```

**Errors:**

| Status | reason | Meaning |
|---|---|---|
| `400` | `invalid_token` | Token signature is invalid |
| `400` | `expired` | QR token has expired |
| `400` | `already_used` | Token was already scanned once |
| `400` | `outside_session_time` | Scanned before session started or after it ended |
| `403` | `wrong_group` | Student is not in this session's group |
| `409` | `already_attended` | Student already has an attendance record for this session |

> All failed scans are automatically saved to `unauthorized_access_logs`.

---

### POST /attendance/manual
Professor manually marks a student present. **Professor only.**

**Request body:**
```json
{
  "sessionId": "uuid",
  "studentId": "uuid"
}
```

**Success — 201:**
```json
{
  "attendanceId": "uuid",
  "sessionId":    "uuid",
  "studentId":    "uuid",
  "checkInAt":    "2025-04-10T09:10:00Z",
  "method":       "manual"
}
```

---

### GET /attendance/session/:sessionId
All attendance records for a session. **Professor (own sessions) or Admin.**

**Success — 200:**
```json
[
  {
    "id":        "uuid",
    "checkInAt": "2025-04-10T09:05:00Z",
    "method":    "qr",
    "student": {
      "id":          "uuid",
      "name":        "Akram Aggoun",
      "urn":         "202312001",
      "studentCode": "STU-001"
    }
  }
]
```

---

### GET /attendance/student/:studentId
Attendance history for a student. **Student (own records) or Admin.**

**Success — 200:**
```json
[
  {
    "id":        "uuid",
    "checkInAt": "2025-04-10T09:05:00Z",
    "method":    "qr",
    "session": {
      "id":         "uuid",
      "courseName": "Algorithms & Data Structures",
      "startTime":  "2025-04-10T09:00:00Z",
      "endTime":    "2025-04-10T11:00:00Z"
    }
  }
]
```

---

## Rooms (Laboratories)

### GET /rooms
List all laboratories. **All roles.**

**Success — 200:**
```json
[
  {
    "id":         "uuid",
    "name":       "Algorithms Lab",
    "building":   "Building B",
    "roomNumber": "B204",
    "capacity":   30,
    "isActive":   true
  }
]
```

---

### POST /rooms
Create a laboratory. **Admin only.**

**Request body:**
```json
{
  "name":       "Networks Lab",
  "building":   "Building A",
  "roomNumber": "A101",
  "capacity":   25
}
```

**Success — 201:** same shape as list item.

---

### PUT /rooms/:id
Update a laboratory. **Admin only.**

**Request body:** any subset of the fields above.

**Success — 200:** updated laboratory object.

---

### DELETE /rooms/:id
Delete a laboratory. **Admin only.**

**Success — 200:**
```json
{ "message": "Laboratory deleted" }
```

**Error:** `409` — cannot delete if active sessions reference this lab

---

## Groups

### GET /groups
List all groups. **All roles.**

**Success — 200:**
```json
[
  {
    "id":        "uuid",
    "name":      "CS-G3",
    "yearLevel": 3
  }
]
```

---

### POST /groups
Create a group. **Admin only.**

**Request body:**
```json
{
  "name":      "CS-G4",
  "yearLevel": 3
}
```

**Success — 201:** same shape as list item.

---

### DELETE /groups/:id
Delete a group. **Admin only.**

**Success — 200:**
```json
{ "message": "Group deleted" }
```

---

## Users (Admin only)

### GET /users
List all users. **Admin only.**

**Query parameters (optional):**
```
?role=student     filter by role
?role=professor
?role=admin
```

**Success — 200:**
```json
[
  {
    "id":       "uuid",
    "name":     "Akram Aggoun",
    "role":     "student",
    "isActive": true,
    "urn":      "202312001"
  }
]
```

---

### POST /users
Create a new user. **Admin only.**

**Student request body:**
```json
{
  "name":        "New Student",
  "password":    "secret",
  "role":        "student",
  "urn":         "202312010",
  "studentCode": "STU-010",
  "groupId":     "uuid"
}
```

**Professor request body:**
```json
{
  "name":           "New Professor",
  "password":       "secret",
  "role":           "professor",
  "email":          "newprof@qrono.dz",
  "professorCode":  "PROF-005",
  "department":     "Computer Science"
}
```

**Admin request body:**
```json
{
  "name":     "New Admin",
  "password": "secret",
  "role":     "admin",
  "email":    "newadmin@qrono.dz"
}
```

**Success — 201:** created user object (no password returned).

---

### PUT /users/:id/deactivate
Deactivate a user account. **Admin only.**

**Success — 200:**
```json
{ "message": "User deactivated" }
```

---

## Health Check

### GET /health
Check server and database status. **No auth required.**

**Healthy — 200:**
```json
{
  "status": "healthy",
  "checks": { "database": "ok" }
}
```

**Degraded — 500:**
```json
{
  "status": "degraded",
  "checks": { "database": "fail" }
}
```

---

## Error format

All error responses follow this shape:

```json
{
  "error":   "Unauthorized",
  "message": "Invalid or expired token",
  "reason":  "invalid_token"
}
```

---

## Demo scenario (teacher's 6 steps)

```
Step 1 → POST /auth/login             (professor logs in with email + password)
Step 2 → POST /attendance/sessions    (professor creates a session)
Step 3 → POST /attendance/qr/generate (system generates QR token)
Step 4 → POST /auth/login             (student logs in with URN + password)
Step 5 → POST /attendance/scan        (student scans QR — attendance recorded)
Step 6 → GET  /attendance/session/:id (professor or admin views attendance list)
```
