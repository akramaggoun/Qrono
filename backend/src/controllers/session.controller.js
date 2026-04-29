const prisma = require('../utils/prisma');
const qrService = require('../services/qr.service');
const notificationService = require('../services/notification.service');

exports.createSession = async (req, res) => {
  console.log('📥 CREATE SESSION REQUEST:', req.body);

  const courseName = req.body.courseName || req.body.course_name;
  const startTime = req.body.startTime || req.body.start_time;
  const endTime = req.body.endTime || req.body.end_time;
  const isRecurring = req.body.isRecurring ?? req.body.is_recurring ?? false;
  const recurrence = req.body.recurrence || null;
  const groupId = req.body.groupId || req.body.group_id;
  const labId = req.body.labId || req.body.lab_id;

  if (!courseName || !startTime || !endTime || !groupId || !labId) {
    return res.status(400).json({ message: 'Missing required session fields' });
  }

  const start = new Date(startTime);
  const end = new Date(endTime);

  if (isNaN(start.getTime()) || isNaN(end.getTime())) {
    return res.status(400).json({ message: 'Invalid date format' });
  }
  if (end <= start) {
    return res.status(400).json({ message: 'End time must be after start time' });
  }

  try {
    let professorProfile;

    if (req.user.role === 'admin') {
      const professorId = req.body.professorId;
      if (!professorId) {
        return res.status(400).json({ message: 'professorId is required when admin creates a session' });
      }
      professorProfile = await prisma.professor.findUnique({
        where: { userId: professorId },
        select: { id: true }
      });
    } else {
      professorProfile = await prisma.professor.findUnique({
        where: { userId: req.user.id },
        select: { id: true }
      });
    }

    if (!professorProfile) {
      return res.status(403).json({ message: 'Professor profile not found' });
    }

    // Conflict / Availability Check
    const conflictingSessions = await prisma.session.findMany({
      where: {
        labId: labId,
        status: 'ACTIVE',
        OR: [
          {
            startTime: { lt: end },
            endTime: { gt: start }
          }
        ]
      }
    });

    if (conflictingSessions.length > 0) {
      // ⬇️ NEW: If we found conflicting sessions, let's try to auto-close them first ⬇️
      await prisma.autoCloseExpiredSessions();
      
      // Re-check after closing
      const stillConflicting = await prisma.session.findMany({
        where: {
          labId: labId,
          status: 'ACTIVE',
          OR: [
            {
              startTime: { lt: end },
              endTime: { gt: start }
            }
          ]
        }
      });

      if (stillConflicting.length > 0) {
        return res.status(409).json({ message: 'Laboratory already occupied at this time' });
      }
    }

    // Create Session
    const session = await prisma.session.create({
      data: {
        courseName,
        startTime: start,
        endTime: end,
        isRecurring: isRecurring || false,
        recurrence: recurrence || null,
        professorId: professorProfile.id,
        groupId,
        labId,
        status: 'ACTIVE'
      },
      include: {
        lab: { select: { name: true } }
      }
    });

    const students = await prisma.user.findMany({
      where: { student: { groupId: groupId } }
    });

    for (const student of students) {
      await notificationService.createAndSendNotification(student.id, {
        title: "notif_session_start_title",
        body: `notif_session_start_body|${courseName}|${session.lab.name}`,
        type: "SESSION_STARTED",
        data: { sessionId: session.id, courseName: courseName, labName: session.lab.name }
      });
    }

    // Generate QR Code
    const qrExpiration = new Date(end);
    qrExpiration.setMinutes(qrExpiration.getMinutes() + 5);

    const qrToken = qrService.createQrToken(session.id, qrExpiration);

    const qrCodeRecord = await prisma.qrCode.create({
      data: {
        sessionId: session.id,
        token: qrToken,
        validFrom: start,
        validUntil: qrExpiration,
        isRevoked: false
      }
    });

    res.status(201).json({
      message: 'Session created successfully',
      session: {
        id: session.id,
        course_name: session.courseName,
        start_time: session.startTime.toISOString(),
        end_time: session.endTime.toISOString(),
        is_recurring: session.isRecurring,
        recurrence: session.recurrence,
        professor_id: session.professorId.toString(),
        group_id: session.groupId.toString(),
        lab_id: session.labId.toString(),
        qr_code: {
          token: qrToken,
          valid_until: qrExpiration.toISOString()
        }
      }
    });

  } catch (error) {
    console.error('Create Session Error:', error.message);
    res.status(500).json({ message: 'Failed to create session', error: error.message });
  }
};

exports.getMySessions = async (req, res) => {
  try {
    // ⬇️ ADDED: Auto-close expired sessions before fetching ⬇️
    if (prisma.autoCloseExpiredSessions) {
      await prisma.autoCloseExpiredSessions();
    }

    const professorProfile = await prisma.professor.findUnique({
      where: { userId: req.user.id },
      select: { id: true, userId: true }
    });

    if (!professorProfile) {
      return res.status(403).json({ message: 'Professor profile not found' });
    }

    // ⬇️ CLEANUP LOGIC: Remove sessions for THIS USER that are not in 'ACTIVE' but still exist unexpectedly ⬇️
    // This handles duplicates if a background process failed to sync status properly
    
    const sessionsData = await prisma.session.findMany({
      where: { professorId: professorProfile.id },
      include: {
        group: { select: { name: true, yearLevel: true } },
        lab: { select: { name: true, roomNumber: true, building: true } },
        qrCodes: { where: { isRevoked: false }, select: { token: true, validUntil: true } },
        _count: { select: { attendance: true } }
      },
      orderBy: { startTime: 'desc' }
    });

    // ⬇️ UNIQUE FILTER: If two sessions have exactly the same time, group, and lab, it's a double ⬇️
    // We filter them out before sending to the mobile app
    const uniqueSessions = [];
    const seenHashes = new Set();

    for (const session of sessionsData) {
      const hash = `${session.startTime.getTime()}_${session.groupId}_${session.labId}`;
      if (!seenHashes.has(hash)) {
        seenHashes.add(hash);
        uniqueSessions.push(session);
      }
    }

    const sessions = uniqueSessions.map(s => {
      const { qrCodes, ...rest } = s;
      return {
        ...rest,
        qr_code: qrCodes.length > 0 ? { token: qrCodes[0].token, valid_until: qrCodes[0].validUntil } : null
      };
    });

    res.status(200).json({ sessions });

  } catch (error) {
    console.error('Get My Sessions Error:', error.message);
    res.status(500).json({ message: 'Failed to fetch sessions', error: error.message });
  }
};

exports.closeSession = async (req, res) => {
  const { id } = req.params;

  try {
    const session = await prisma.session.findUnique({
      where: { id },
      include: { qrCodes: true }
    });

    if (!session) {
      return res.status(404).json({ message: 'Session not found' });
    }

    const now = new Date();

    const updatedSession = await prisma.session.update({
      where: { id },
      data: {
        endTime: now,
        status: 'CLOSED'
      }
    });

    const students = await prisma.user.findMany({
      where: { student: { groupId: session.groupId } }
    });

    for (const student of students) {
      await notificationService.createAndSendNotification(student.id, {
        title: "🔒 Session ended",
        body: `The ${session.courseName} session is now closed.`,
        type: "SESSION_CLOSED",
        data: { sessionId: session.id }
      });
    }

    if (session.qrCodes.length > 0) {
      await prisma.qrCode.updateMany({
        where: { sessionId: id, isRevoked: false },
        data: { isRevoked: true }
      });
    }

    res.status(200).json({
      message: 'Session closed successfully',
      session: updatedSession
    });

  } catch (error) {
    console.error('Close Session Error:', error.message);
    res.status(500).json({ message: 'Failed to close session', error: error.message });
  }
};

exports.getSessionAttendances = async (req, res) => {
  const { id } = req.params;

  try {
    const session = await prisma.session.findUnique({
      where: { id },
      select: { groupId: true }
    });

    if (!session) {
      return res.status(404).json({ message: 'Session not found' });
    }

    const groupStudents = await prisma.student.findMany({
      where: { groupId: session.groupId },
      include: {
        user: { select: { name: true, role: true } },
        group: { select: { name: true } }
      }
    });

    const attendances = await prisma.attendance.findMany({
      where: { sessionId: id }
    });

    const attendanceMap = {};
    attendances.forEach(a => {
      attendanceMap[a.studentId] = a;
    });

    const fullAttendanceList = groupStudents.map(student => {
      const record = attendanceMap[student.id];
      return {
        student: student,
        status: record ? 'present' : 'absent',
        checkInAt: record ? record.checkInAt : null,
        method: record ? record.method : null
      };
    });

    res.status(200).json({
      sessionId: id,
      totalStudents: fullAttendanceList.length,
      presentCount: attendances.length,
      absentCount: fullAttendanceList.length - attendances.length,
      attendances: fullAttendanceList
    });

  } catch (error) {
    console.error('Get Attendances Error:', error.message);
    res.status(500).json({ message: 'Failed to fetch attendances', error: error.message });
  }
};

exports.markManualAttendance = async (req, res) => {
  const { id: sessionId } = req.params;
  const { studentId } = req.body;

  if (!studentId) {
    return res.status(400).json({ message: 'studentId is required' });
  }

  try {
    const session = await prisma.session.findUnique({
      where: { id: sessionId },
      select: { id: true, courseName: true }
    });

    if (!session) {
      return res.status(404).json({ message: 'Session not found' });
    }

    const studentProfile = await prisma.student.findUnique({
      where: { id: studentId },
      include: { user: { select: { id: true, name: true } } }
    });

    if (!studentProfile) {
      return res.status(404).json({ message: 'Student profile not found' });
    }

    const existingAttendance = await prisma.attendance.findUnique({
      where: {
        sessionId_studentId: {
          sessionId,
          studentId: studentProfile.id
        }
      }
    });

    if (existingAttendance) {
      return res.status(409).json({ message: 'Student is already present' });
    }

    const attendance = await prisma.attendance.create({
      data: {
        sessionId,
        studentId: studentProfile.id,
        checkInAt: new Date(),
        method: 'manual'
      }
    });

    await notificationService.createAndSendNotification(studentProfile.user.id, {
      title: "✅ Manual registration",
      body: `Your attendance for ${session.courseName} has been marked manually by the professor.`,
      type: "ATTENDANCE_RECORDED",
      data: { attendanceId: attendance.id, sessionId: sessionId }
    });

    res.status(201).json({
      message: 'Attendance recorded successfully',
      attendance
    });

  } catch (error) {
    console.error('Manual Attendance Error:', error.message);
    res.status(500).json({ message: 'Failed to mark manual attendance', error: error.message });
  }
};