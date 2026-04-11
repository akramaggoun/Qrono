# Qrono

**University Laboratory Attendance System with Wireless QR Scanning**

Qrono is a full-stack attendance management system designed for university labs. Professors generate time-limited QR codes for their sessions, and students scan them to check in — from any device, anywhere, using Cloudflare Tunnel for wireless access.

---

## Features

- **QR-Based Attendance** — Professors generate secure, time-limited QR codes; students scan to check in
- **Wireless Access** — Students can scan QR codes from any network via Cloudflare Tunnel (no local Wi-Fi required)
- **Role-Based System** — Separate dashboards for Admins, Professors, and Students
- **Real-Time Notifications** — Socket.IO push notifications for attendance events
- **Unauthorized Access Detection** — Logs and alerts when students scan outside their assigned sessions
- **Session Management** — Create, schedule, and manage lab sessions with recurring support
- **Multi-Platform** — Flutter app runs on Android, iOS, Web, and desktop

---

## Architecture

```
┌─────────────────┐       HTTPS        ┌────────────────────┐       HTTP        ┌──────────────┐
│  Student Phone  │ ──────────────────► │  Cloudflare Tunnel │ ───────────────► │  Backend API │
│  (Flutter App)  │                     │  (cloudflared)     │                  │  (Express.js)│
└─────────────────┘                     └────────────────────┘                  └──────┬───────┘
                                                                                       │
                                                                                       ▼
                                                                               ┌──────────────┐
                                                                               │  PostgreSQL  │
                                                                               │  (Prisma ORM)│
                                                                               └──────────────┘
```

---

## Tech Stack

| Layer        | Technology                          |
|--------------|-------------------------------------|
| **Backend**  | Node.js, Express.js, Prisma ORM     |
| **Database** | PostgreSQL                          |
| **Mobile**   | Flutter (Dart)                      |
| **Auth**     | JWT (access + refresh tokens)       |
| **Realtime** | Socket.IO                           |
| **Tunnel**   | Cloudflare Tunnel (`cloudflared`)   |

---

## Project Structure

```
Qrono/
├── backend/                  # Express.js REST API
│   ├── prisma/               #   Prisma schema & migrations
│   ├── src/
│   │   ├── controllers/      #   Route handlers
│   │   ├── middleware/        #   Auth, validation
│   │   ├── routes/            #   API route definitions
│   │   ├── services/          #   Business logic & notifications
│   │   ├── utils/             #   Prisma client, helpers
│   │   └── app.js             #   Express app entry point
│   └── .env.example           #   Environment template
├── mobile/flutter_app/       # Flutter mobile/web app
│   └── lib/
│       ├── core/              #   Config, constants, API client
│       ├── models/            #   Data models
│       ├── providers/         #   State management (Provider)
│       └── screens/           #   UI (admin, professor, student)
├── devops/tunnel/            # Cloudflare Tunnel scripts
│   ├── config.yaml            #   Tunnel config template
│   ├── setup-tunnel.bat/.sh   #   Automated setup
│   ├── start-tunnel.bat/.sh   #   Start tunnel
│   └── stop-tunnel.bat/.sh    #   Stop tunnel
├── WIRELESS_SETUP.md         # Detailed wireless setup guide
└── package.json              # Root scripts (tunnel management)
```

---

## Getting Started

### Prerequisites

- **Node.js** ≥ 18
- **PostgreSQL** running locally or remotely
- **Flutter SDK** ≥ 3.11
- **cloudflared** ([install guide](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/)) — only for wireless testing

### 1. Clone the repo

```bash
git clone https://github.com/akramaggoun/Qrono.git
cd Qrono
```

### 2. Set up the backend

```bash
cd backend
cp .env.example .env
# Edit .env with your PostgreSQL credentials:
#   DATABASE_URL="postgresql://postgres:yourpassword@localhost:5432/qrono?schema=public"
#   JWT_SECRET="your_jwt_secret"
#   QR_SECRET="your_qr_secret"

npm install
npx prisma migrate dev --name init    # Create database tables
npx prisma db seed                    # (Optional) Seed sample data
npm start                             # Starts on http://localhost:3000
```

Verify: open http://localhost:3000/api/health in your browser.

### 3. Run the Flutter app

```bash
cd mobile/flutter_app
flutter pub get
flutter run -d chrome          # Web
flutter run -d <device_id>     # Android/iOS
```

The app defaults to `http://localhost:3000/api` as the backend URL.

### 4. Test wireless features (optional)

No Cloudflare account needed — use a free quick tunnel:

```bash
# In a separate terminal:
cloudflared tunnel --url http://localhost:3000
```

You'll get a public URL like `https://random-words.trycloudflare.com`. Then in the Flutter app:

1. Go to **Settings ⚙️ → Wireless (Cloudflare Tunnel)**
2. Paste the tunnel URL
3. Tap **Apply** — the app now reaches your backend over the internet

> **Note:** Quick tunnel URLs change every time you restart `cloudflared`. See [WIRELESS_SETUP.md](WIRELESS_SETUP.md) for permanent tunnel setup.

---

## API Endpoints

| Method | Endpoint                         | Description                     |
|--------|----------------------------------|---------------------------------|
| POST   | `/api/auth/login`                | Login (returns JWT)             |
| POST   | `/api/auth/logout`               | Logout                          |
| POST   | `/api/auth/refresh`              | Refresh access token            |
| GET    | `/api/users/profile`             | Get current user profile        |
| GET    | `/api/sessions`                  | List sessions                   |
| POST   | `/api/sessions`                  | Create a new session            |
| POST   | `/api/presences/scan`            | Scan QR code for attendance     |
| GET    | `/api/presences/my-attendances`  | Student's attendance history    |
| GET    | `/api/laboratories`              | List laboratories               |
| GET    | `/api/groups`                    | List student groups             |
| GET    | `/api/statistics`                | Attendance statistics           |
| GET    | `/api/notifications`             | Get notifications               |
| GET    | `/api/health`                    | Health check + DB status        |

---

## Roles

| Role        | Capabilities                                                     |
|-------------|------------------------------------------------------------------|
| **Admin**   | Manage users, groups, labs; view all statistics                  |
| **Professor** | Create sessions, generate QR codes, view attendance, record manually |
| **Student** | Scan QR codes, view own attendance history                      |

---

## Environment Variables

Copy `backend/.env.example` to `backend/.env` and configure:

| Variable       | Description                              | Example                                              |
|----------------|------------------------------------------|------------------------------------------------------|
| `DATABASE_URL` | PostgreSQL connection string             | `postgresql://postgres:pass@localhost:5432/qrono`    |
| `JWT_SECRET`   | Secret key for JWT signing               | Any secure random string                             |
| `QR_SECRET`    | Secret key for QR code token signing     | Any secure random string                             |
| `PORT`         | Backend server port                      | `3000`                                               |
| `NODE_ENV`     | Environment mode                         | `development`                                        |

---

## Scripts

From the project root:

```bash
npm run backend:start     # Start backend server
npm run backend:dev       # Start with auto-reload (nodemon)
npm run tunnel:setup      # Set up named Cloudflare tunnel
npm run tunnel:start      # Start the tunnel
npm run tunnel:stop       # Stop the tunnel
npm run tunnel:status     # Check tunnel status
```

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Set up your local environment (see [Getting Started](#getting-started))
4. To test wireless features, run `cloudflared tunnel --url http://localhost:3000` (see [WIRELESS_SETUP.md](WIRELESS_SETUP.md))
5. Commit and push your changes
6. Open a Pull Request

---

## License

ISC
