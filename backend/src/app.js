const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { createServer } = require('http');

dotenv.config();

const notificationService = require('./services/notification.service');
const globalLimiter = require('./middleware/rate-limiter.middleware');

const app = express();
const httpServer = createServer(app);

notificationService.init(httpServer);

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

app.use((err, req, res, next) => {
  console.error('Global Error:', err.stack);
  res.status(500).json({ 
    message: 'Internal Server Error', 
    error: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong' 
  });
});

const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
  console.log(`Qrono Backend running on http://localhost:${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
