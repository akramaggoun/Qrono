const prisma = require('../utils/prisma');

exports.getStatistics = async (req, res) => {
  try {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

    const [
      totalUsers,
      activeSessionsCount,
      todayAttendanceCount,
      todayUnauthorizedCount,
      activeLabs
    ] = await Promise.all([
      prisma.user.count(),
      prisma.session.count({
        where: {
          startTime: { lte: now },
          endTime: { gte: now }
        }
      }),

      prisma.attendance.count({
        where: {
          checkInAt: {
            gte: startOfDay,
            lte: endOfDay
          }
        }
      }),

      prisma.unauthorizedAccessLog.count({
        where: {
          occurredAt: {
            gte: startOfDay,
            lte: endOfDay
          }
        }
      }),

      prisma.laboratory.findMany({
        where: { isActive: true },
        select: {
          id: true,
          name: true,
          building: true,
          roomNumber: true,
          capacity: true
        },
        orderBy: [{ building: 'asc' }, { roomNumber: 'asc' }]
      })
    ]);

    const stats = {
      totalUsers,
      activeSessions: activeSessionsCount,
      todayAttendance: todayAttendanceCount,
      unauthorizedToday: todayUnauthorizedCount,
      laboratories: activeLabs,
      generatedAt: now
    };

    res.status(200).json(stats);

  } catch (error) {
    console.error('Get Statistics Error:', error.message);
    res.status(500).json({ message: 'Failed to fetch statistics', error: error.message });
  }
};
