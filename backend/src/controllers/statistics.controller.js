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
          status: 'ACTIVE',
          startTime: { lte: now },
          endTime: { gte: now }
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
  const { studentId } = req.params;

  try {
    const student = await prisma.student.findUnique({
      where: { userId: studentId },
      include: {
        user: { select: { id: true, name: true, createdAt: true } },
        group: { select: { id: true, name: true } }
      }
    });

    if (!student) {
      return res.status(404).json({ message: 'Student not found' });
    }

    const totalScheduled = await prisma.session.count({
      where: { groupId: student.groupId }
    });

    const attendances = await prisma.attendance.findMany({
      where: { studentId: student.id },
      include: {
        session: { 
          select: { 
            courseName: true, 
            startTime: true,
            lab: { select: { name: true } }
          } 
        }
      },
      orderBy: { checkInAt: 'desc' }
    });

    const unauthorized = await prisma.unauthorizedAccessLog.findMany({
      where: { studentId: student.id },
      include: {
        session: { select: { courseName: true } },
        lab: { select: { name: true } }
      },
      orderBy: { occurredAt: 'desc' }
    });

    res.status(200).json({
      student: {
        id: student.id,
        userId: student.userId,
        name: student.user.name,
        email: student.urn + "@student.univ-khenchela.dz",
        groupName: student.group?.name || "N/A",
        createdAt: student.user.createdAt
      },
      attendanceCount: attendances.length,
      absentCount: Math.max(0, totalScheduled - attendances.length),
      totalScheduled: totalScheduled,
      unauthorizedCount: unauthorized.length,
      recentAttendances: attendances,
      recentUnauthorized: unauthorized
    });

  } catch (error) {
    console.error('Get Student Stats Error:', error.message);
    res.status(500).json({ message: 'Failed to fetch student statistics', error: error.message });
  }
};

exports.getProfessorStats = async (req, res) => {
  const userId = req.user.id;

  try {
    const professor = await prisma.professor.findUnique({
      where: { userId },
      select: { id: true }
    });

    if (!professor) {
      return res.status(404).json({ message: 'Professor profile not found' });
    }

    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

    const [totalSessions, todaySessions, totalAttendance] = await Promise.all([
      prisma.session.count({ where: { professorId: professor.id } }),
      prisma.session.count({
        where: {
          professorId: professor.id,
          startTime: { gte: startOfDay, lte: endOfDay }
        }
      }),
      prisma.attendance.count({
        where: {
          session: { professorId: professor.id }
        }
      })
    ]);

    // Simple attendance rate: (attendances / (sessions * expected students)) 
    // For simplicity, we'll return the raw numbers and let the UI calculate rate if needed
    const attendanceRate = totalSessions > 0 ? (totalAttendance / totalSessions).toFixed(1) : "0";

    res.json({
      totalSessions,
      todaySessions,
      todayAttendance: totalAttendance, // Usually refers to total accumulated or today's depending on UI context
      attendanceRate
    });
  } catch (error) {
    console.error('Get Professor Stats Error:', error);
    res.status(500).json({ message: 'Failed to fetch statistics' });
  }
};

exports.checkExclusion = async (req, res) => {
  const { studentId, courseName } = req.query;
  const professorUserId = req.user.id;

  try {
    const professor = await prisma.professor.findUnique({ where: { userId: professorUserId } });
    if (!professor) return res.status(403).json({ message: 'Only professors can check exclusions' });

    const exclusion = await prisma.exclusion.findFirst({
      where: {
        studentId,
        courseName,
        professorId: professor.id
      }
    });

    res.json({ isExcluded: !!exclusion });
  } catch (error) {
    res.status(500).json({ message: 'Failed to check exclusion', error: error.message });
  }
};

exports.getDetailedAbsences = async (req, res) => {
  const { studentId } = req.params;
  const { courseName } = req.query;

  try {
    const student = await prisma.student.findUnique({
      where: { id: studentId },
      include: { group: true }
    });

    if (!student) return res.status(404).json({ message: 'Student not found' });

    // 1. Get all sessions for this course and group
    const sessions = await prisma.session.findMany({
      where: {
        groupId: student.groupId,
        courseName: courseName
      },
      select: { id: true, startTime: true }
    });

    // 2. Get all attendances for this student in this course
    const attendances = await prisma.attendance.findMany({
      where: {
        studentId: student.id,
        session: { courseName: courseName }
      },
      select: { sessionId: true }
    });

    const attendedSessionIds = new Set(attendances.map(a => a.sessionId));
    const absentSessions = sessions.filter(s => !attendedSessionIds.has(s.id));

    res.json({
      totalSessions: sessions.length,
      attendanceCount: attendances.length,
      absenceCount: absentSessions.length,
      absentSessions
    });
  } catch (error) {
    console.error('Get Detailed Absences Error:', error);
    res.status(500).json({ message: 'Failed to fetch detailed absences' });
  }
};

exports.toggleExclusion = async (req, res) => {
  const { studentId, courseName, exclude } = req.body;
  const professorUserId = req.user.id;

  try {
    const professor = await prisma.professor.findUnique({ where: { userId: professorUserId } });
    if (!professor) return res.status(403).json({ message: 'Only professors can toggle exclusions' });

    if (exclude) {
      await prisma.exclusion.upsert({
        where: {
          studentId_professorId_courseName: {
            studentId,
            professorId: professor.id,
            courseName
          }
        },
        update: {},
        create: {
          studentId,
          professorId: professor.id,
          courseName
        }
      });
    } else {
      await prisma.exclusion.deleteMany({
        where: {
          studentId,
          professorId: professor.id,
          courseName
        }
      });
    }

    // Notify the student about their exclusion status
    try {
      const notificationService = require('../services/notification.service');
      const student = await prisma.student.findUnique({ 
        where: { id: studentId },
        include: { user: true } 
      });

      if (student) {
        if (exclude) {
          await notificationService.createAndSendNotification(student.userId, {
            title: '🚫 Course Exclusion',
            body: `You have been excluded from the course: ${courseName}. Please contact the administration.`,
            type: 'EXCLUSION_ACTIVE',
            data: { courseName, professorId: professor.id.toString() }
          });
        } else {
          await notificationService.createAndSendNotification(student.userId, {
            title: '✅ Exclusion Lifted',
            body: `Your exclusion from ${courseName} has been lifted. You can now attend and scan QR codes.`,
            type: 'EXCLUSION_INACTIVE',
            data: { courseName }
          });
        }
      }
    } catch (notifErr) {
      console.error('Failed to send exclusion notification:', notifErr.message);
    }

    res.json({ message: 'Status updated successfully', isExcluded: exclude });
  } catch (error) {
    console.error('Toggle Exclusion Error:', error);
    res.status(500).json({ message: 'Failed to toggle exclusion', error: error.message });
  }
};

