const prisma = require('../utils/prisma');
const qrService = require('../services/qr.service');
const notificationService = require('../services/notification.service');

exports.createSession = async (req, res) => {
  console.log('📥 CREATE SESSION REQUEST:', req.body);
  
  // Support both camelCase and snake_case (Fix for Bug 3)
  const courseName = req.body.courseName || req.body.course_name;
  const startTime = req.body.startTime || req.body.start_time;
  const endTime = req.body.endTime || req.body.end_time;
  const isRecurring = req.body.isRecurring ?? req.body.is_recurring ?? false;
  const recurrence = req.body.recurrence || null;
  const groupId = req.body.groupId || req.body.group_id;
  const labId = req.body.labId || req.body.lab_id;
  const scheduleId = req.body.scheduleId || req.body.schedule_id || null;

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
    const professorProfile = await prisma.professor.findUnique({
      where: { userId: req.user.id },
      select: { id: true }
    });

    if (!professorProfile) {
      return res.status(403).json({ message: 'Only professors can create sessions' });
    }

    // Sequence Diagram Step 3 : Conflict / Availability Check
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
      return res.status(409).json({ message: 'Laboratory already occupied at this time' });
    }

    // Sequence Diagram Step 4 : Create Session
    const session = await prisma.session.create({
      data: {
        courseName,
        startTime: start,
        endTime: end,
        isRecurring: isRecurring || false,
        recurrence: recurrence || null,
        professorId: professorProfile.id,
        scheduleId: scheduleId,
        groupId,
        labId,
        status: 'ACTIVE'
      },
      include: {
        lab: { select: { name: true } },
        schedule: { select: { name: true } }
      }
    });

    const students = await prisma.user.findMany({
      where: { student: { groupId: groupId } }
    });

    for (const student of students) {
      await notificationService.createAndSendNotification(student.id, {
        title: "New session",
        body: `The session ${courseName} is starting at ${session.lab.name}.`,
        type: "SESSION_STARTED",
        data: { sessionId: session.id }
      });
    }

    // Sequence Diagram Step 5 : Generate QR Code
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
        schedule_id: session.scheduleId ? session.scheduleId.toString() : null,
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
    const professorProfile = await prisma.professor.findUnique({
      where: { userId: req.user.id },
      select: { id: true }
    });

    if (!professorProfile) {
      return res.status(403).json({ message: 'Professor profile not found' });
    }

    const sessionsData = await prisma.session.findMany({
      where: { professorId: professorProfile.id },
      include: {
        group: { select: { name: true, yearLevel: true } },
        lab: { select: { name: true, roomNumber: true, building: true } },
        schedule: { select: { name: true } },
        qrCodes: { where: { isRevoked: false }, select: { token: true, validUntil: true } },
        _count: { select: { attendance: true } }
      },
      orderBy: { startTime: 'desc' }
    });

    const sessions = sessionsData.map(s => {
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
    
    // Sequence Diagram Step 7 : Close Session
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
        title: "Session ended",
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

    // 1. Get all students that belong to the session's group
    const groupStudents = await prisma.student.findMany({
      where: { groupId: session.groupId },
      include: {
        user: { select: { name: true, role: true } },
        group: { select: { name: true } }
      }
    });

    // 2. Get the actual attendance records
    const attendances = await prisma.attendance.findMany({
      where: { sessionId: id }
    });

    // 3. Create a map for fast lookup
    const attendanceMap = {};
    attendances.forEach(a => {
      attendanceMap[a.studentId] = a;
    });

    // 4. Combine students with their attendance status
    const fullAttendanceList = groupStudents.map(student => {
      const record = attendanceMap[student.id];
      return {
        id: record ? record.id : `absent-${student.id}`,
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
