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

exports.getStudentStats = async (req, res) => {
  const { id } = req.params;
  try {
    const student = await prisma.student.findUnique({
      where: { userId: id }, // Changed from id to userId
      include: { group: true }
    });

    if (!student) return res.status(404).json({ message: 'Student not found' });

    const totalGroupSessions = await prisma.session.count({
      where: { groupId: student.groupId, status: 'CLOSED' }
    });

    const attendedCount = await prisma.attendance.count({
      where: { studentId: student.id }
    });

    const absenceCount = Math.max(0, totalGroupSessions - attendedCount);
    const attendanceRate = totalGroupSessions > 0 ? (attendedCount / totalGroupSessions) * 100 : 0;

    res.status(200).json({
      totalSessions: totalGroupSessions,
      attendedCount,
      absenceCount,
      attendanceRate: attendanceRate.toFixed(1)
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getProfessorStats = async (req, res) => {
  const { id } = req.params;
  try {
    const professor = await prisma.professor.findUnique({
      where: { userId: id }
    });

    if (!professor) return res.status(404).json({ message: 'Professor not found' });

    const sessionCount = await prisma.session.count({
      where: { professorId: professor.id }
    });

    // Average attendance in this professor's sessions
    const sessions = await prisma.session.findMany({
      where: { professorId: professor.id, status: 'CLOSED' },
      include: { 
        attendance: true,
        group: { include: { _count: { select: { students: true } } } }
      }
    });

    let totalPossible = 0;
    let totalActual = 0;
    sessions.forEach(s => {
      totalActual += s.attendance.length;
      totalPossible += s.group._count.students;
    });

    const avgAttendanceRate = totalPossible > 0 ? (totalActual / totalPossible) * 100 : 0;

    res.status(200).json({
      sessionCount,
      avgAttendanceRate: avgAttendanceRate.toFixed(1),
      totalStudentsEngaged: totalActual
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getGroupStats = async (req, res) => {
  const { id } = req.params;
  try {
    const [totalSessions, studentCount] = await Promise.all([
      prisma.session.count({ where: { groupId: id } }),
      prisma.student.count({ where: { groupId: id } })
    ]);

    const totalAttendanceRecords = await prisma.attendance.count({
      where: { session: { groupId: id } }
    });

    const possibleAttendances = totalSessions * studentCount;
    const globalAttendanceRate = possibleAttendances > 0 ? (totalAttendanceRecords / possibleAttendances) * 100 : 0;

    res.status(200).json({
      totalSessions,
      studentCount,
      globalAttendanceRate: globalAttendanceRate.toFixed(1),
      totalAttendances: totalAttendanceRecords
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getLabStats = async (req, res) => {
  const { id } = req.params;
  try {
    const [usageCount, totalScans, unauthorizedCount] = await Promise.all([
      prisma.session.count({ where: { labId: id } }),
      prisma.attendance.count({ where: { session: { labId: id } } }),
      prisma.unauthorizedAccessLog.count({ where: { labId: id } })
    ]);

    res.status(200).json({
      usageCount,
      totalScans,
      unauthorizedCount
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
