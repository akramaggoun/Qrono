# Qrono Backend API Specification

**Base URL:** `http://localhost:3000`  
**Environment:** Node.js / Express  
**Authentication:** Bearer Token (JWT)  
**Roles:** `admin`, `professor`, `student`

---

## Global Configuration

- **Content-Type:** `application/json`
- **Authentication Header:** `Authorization: Bearer <token>`
  - Required for all endpoints **except** `/api/auth/login`.
- **Error Handling:**
  - `4xx`: Client errors (Unauthorized, Forbidden, Bad Request).
  - `500`: Internal Server Error (Detailed message in `development`, generic in `production`).

---

## 1. Authentication

Public endpoints for user login.

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/login` | Authenticate user and receive token | Public |

> **Note:** Request body typically includes `email` and `password`.

---

## 2. Users Management

*Restricted to `admin` role.*

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/users` | Retrieve all users | `admin` |
| `POST` | `/api/users` | Create a new user | `admin` |
| `PUT` | `/api/users/:id` | Update user details | `admin` |
| `DELETE` | `/api/users/:id` | Delete a user | `admin` |

---

## 3. Laboratories

Manage laboratory rooms and resources.

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/laboratories` | List all laboratories | `admin`, `professor` |
| `POST` | `/api/laboratories` | Create a new laboratory | `admin` |
| `PUT` | `/api/laboratories/:id` | Update laboratory details | `admin` |
| `DELETE` | `/api/laboratories/:id` | Delete a laboratory | `admin` |

---

## 4. Groups

Manage student/professor groups.

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/groups` | List all groups | `admin`, `professor` |
| `POST` | `/api/groups` | Create a new group | `admin` |
| `PUT` | `/api/groups/:id` | Update group details | `admin` |
| `DELETE` | `/api/groups/:id` | Delete a group | `admin` |

---

## 5. Sessions

Handle class sessions and lifecycle.

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/sessions` | Create a new session | `professor`, `admin` |
| `GET` | `/api/sessions/my-sessions` | Get sessions created by logged-in professor | `professor` |
| `PATCH` | `/api/sessions/:id/close` | Close an active session | `professor`, `admin` |
| `GET` | `/api/sessions/:id/attendances` | Get attendance list for a specific session | `professor`, `admin` |

---

## 6. Presences (Attendance)

*Restricted to `student` role.*

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/presences/scan` | Scan QR code to mark attendance | `student` |
| `GET` | `/api/presences/my-attendances` | Get current student's attendance history | `student` |

---

## 7. Statistics

*Restricted to `admin` role.*

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/statistics` | Get global system statistics | `admin` |

---

## 8. Notifications

Available to any authenticated user.

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/notifications` | Get user notifications | Authenticated |
| `PATCH` | `/api/notifications/:id/read` | Mark a specific notification as read | Authenticated |
| `PATCH` | `/api/notifications/read-all` | Mark all user notifications as read | Authenticated |

---

## 9. Unauthorized Logs

*Restricted to `admin` role. Security auditing.*

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/unauthorized-logs` | Get logs of unauthorized access attempts | `admin` |

---

## Role Summary

- **admin**: Full access to all resources (Users, Labs, Groups, Sessions, Stats, Logs).
- **professor**: Can view Labs/Groups, create/manage Sessions, and view Attendances. Cannot manage Users or System Stats.
- **student**: Can only scan QR codes for attendance and view their own history/notifications.
