const prisma = require('../utils/prisma');
const notificationService = require('../services/notification.service');

exports.getNotifications = async (req, res) => {
  try {
    const notifications = await prisma.notification.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' }
    });
    res.status(200).json({ notifications });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch notifications', error: error.message });
  }
};

exports.markAsRead = async (req, res) => {
  const { id } = req.params;
  try {
    const updated = await prisma.notification.update({
      where: { id, userId: req.user.id },
      data: { isRead: true }
    });

    notificationService.getIO().to(req.user.id).emit('notification:read', { id });

    res.status(200).json({ message: 'Notification marked as read', notification: updated });
  } catch (error) {
    res.status(404).json({ message: 'Notification not found' });
  }
};

exports.markAllAsRead = async (req, res) => {
  try {
    await prisma.notification.updateMany({
      where: { userId: req.user.id, isRead: false },
      data: { isRead: true }
    });

    notificationService.getIO().to(req.user.id).emit('notification:read_all');

    res.status(200).json({ message: 'All notifications marked as read' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update notifications', error: error.message });
  }
};
