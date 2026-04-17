const prisma = require('../utils/prisma');
const { Server } = require('socket.io');
const { admin, isFirebaseInitialized } = require('../utils/firebase');

let io;
exports.init = (httpServer) => {
  io = new Server(httpServer, {
    cors: {
      origin: "*", // frontend URL in production
      methods: ["GET", "POST"]
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.handshake.query.userId;

    if (userId) {
      socket.join(userId);
      console.log(`User ${userId} joined their notification room.`);
    }

    socket.on('disconnect', () => {
      console.log('User disconnected');
    });
  });

  return io;
}

exports.getIO = () => {
  if (!io) throw new Error("Socket.io not initialized!");
  return io;
};

exports.createAndSendNotification = async (userId, { title, body, type, data }) => {
  const notification = await prisma.notification.create({
    data: { userId, title, body, type, data }
  });

  const userRoom = io.sockets.adapter.rooms.get(userId);
  const isOnline = userRoom && userRoom.size > 0;

  if (isOnline) {
    io.to(userId).emit('notification:new', notification);
  } else if (isFirebaseInitialized) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true }
    });

    if (user?.fcmToken) {
      const message = {
        notification: { title, body },
        data: { ...data, type },
        token: user.fcmToken,
      };

      admin.messaging().send(message)
        .then(response => console.log('FCM Success:', response))
        .catch(error => console.error('FCM Error:', error));
    }
  }

  return notification;
};

exports.createAndSendNotification = async (userId, { title, body, type, data }) => {
  const notification = await prisma.notification.create({
    data: {
      userId,
      title,
      body,
      type,
      data,
    }
  });

  if (io) {
    io.to(userId).emit('notification:new', notification);
  }

  return notification;
};

