// Load .env before any module that uses Prisma (DATABASE_URL must exist first).
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { createServer } = require('http');

dotenv.config();

const notificationService = require('./services/notification.service');
const prisma = require('./utils/prisma');
const globalLimiter = require('./middleware/rate-limiter.middleware');

const app = express();
const httpServer = createServer(app);

notificationService.init(httpServer);

// Enhanced CORS configuration for wireless access
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);

    // Allow localhost for development
    if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
      return callback(null, true);
    }

    // Allow Cloudflare tunnel domains
    if (origin.includes('yourdomain.com') || origin.includes('cloudflare') || origin.includes('tunnel')) {
      return callback(null, true);
    }

    // Allow all origins in development mode
    if (process.env.NODE_ENV === 'development') {
      return callback(null, true);
    }

    // Reject other origins in production
    return callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

app.use(cors(corsOptions));
app.use(cors());
app.use(express.json());
app.use('/api/', globalLimiter);

app.use((req, res, next) => {
  const fullPath = req.originalUrl || req.url;
  console.log(`[REQUEST] ${req.method} ${fullPath}`);
  res.on('finish', () => {
    console.log(`[RESPONSE] ${req.method} ${fullPath} -> ${res.statusCode}`);
  });
  next();
});

app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/users', require('./routes/user.routes'));

app.use('/api/laboratories', require('./routes/laboratory.routes'));
app.use('/api/groups', require('./routes/group.routes'));
app.use('/api/statistics', require('./routes/statistics.routes'));
app.use('/api/unauthorized-logs', require('./routes/unauthorized.routes'));

app.use('/api/sessions', require('./routes/session.routes'));
app.use('/api/presences', require('./routes/presence.routes'));

app.use('/api/notifications', require('./routes/notification.routes'));

// Health check including real PostgreSQL connectivity (Prisma)
app.get('/api/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ ok: true, database: 'postgresql', status: 'connected' });
  } catch (e) {
    res.status(503).json({
      ok: false,
      database: 'postgresql',
      status: 'disconnected',
      message: process.env.NODE_ENV === 'development' ? e.message : 'Database unavailable',
    });
  }
});

app.use((err, req, res, next) => {
  console.error('Global Error:', err.stack);
  res.status(500).json({ 
    message: 'Internal Server Error', 
    error: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong' 
  });
});

const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, async () => {
  console.log(`🚀 Qrono Backend running on http://localhost:${PORT}`);
  console.log(`🌐 Wireless Access: Configure Cloudflare tunnel for remote QR scanning`);
  console.log(`📱 Mobile App: Wireless Settings screen sets the tunnel API URL`);
  console.log(`🔧 Environment: ${process.env.NODE_ENV || 'development'}`);
  if (!process.env.DATABASE_URL) {
    console.log('📊 Database: Not configured (set DATABASE_URL in backend/.env)');
  } else {
    try {
      await prisma.$connect();
      console.log('📊 Database: Connected to PostgreSQL');
    } catch (e) {
      console.error('📊 Database: FAILED to connect to PostgreSQL:', e.message);
      console.error('   Fix DATABASE_URL in backend/.env and ensure PostgreSQL is running.');
    }
  }
});
