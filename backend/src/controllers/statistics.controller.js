const prisma = require('../utils/prisma');

exports.getStatistics = async (req, res) => {
  try {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

    const [
      totalUsers,
      totalProfessors,
      totalStudents,
      totalGroups,
      activeSessionsCount,
      todaySessionsCount,
      todayAttendanceCount,
      todayUnauthorizedCount,
      activeLabs
    ] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { role: 'professor' } }),
      prisma.user.count({ where: { role: 'student' } }),
      prisma.group.count(),
      prisma.session.count({
        where: {
          status: 'ACTIVE'
        }
      }),
      prisma.session.count({
        where: {
          startTime: {
            gte: startOfDay,
            lte: endOfDay
          }
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

    const attendanceRate = totalStudents > 0 ? Math.min(100, Math.round((todayAttendanceCount / totalStudents) * 100)) : 0;

    const stats = {
      totalUsers,
      totalProfessors,
      totalStudents,
      totalGroups,
      todaySessions: todaySessionsCount,
      attendanceRate,
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
