const prisma = require('../utils/prisma');
const qrService = require('../services/qr.service'); 

exports.createSession = async (req, res) => {
  const { courseName, startTime, endTime, isRecurring, recurrence, groupId, labId } = req.body;

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

    const session = await prisma.session.create({
      data: {
        courseName,
        startTime: start,
        endTime: end,
        isRecurring: isRecurring || false,
        recurrence: recurrence || null,
        professorId: professorProfile.id,
        groupId,
        labId
      }
    });

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
        ...session,
        qrCode: {
          token: qrToken,
          validUntil: qrExpiration
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

    const sessions = await prisma.session.findMany({
      where: { professorId: professorProfile.id },
      include: {
        group: { select: { name: true, yearLevel: true } },
        lab: { select: { name: true, roomNumber: true, building: true } },
        _count: { select: { attendance: true } }
      },
      orderBy: { startTime: 'desc' }
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
      data: { endTime: now }
    });

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
    const attendances = await prisma.attendance.findMany({
      where: { sessionId: id },
      include: {
        student: {
          include: {
            user: { select: { name: true, role: true } },
            group: { select: { name: true } }
          }
        },
        checkInAt: true,
        method: true
      },
      orderBy: { checkInAt: 'asc' }
    });

    res.status(200).json({ 
      sessionId: id,
      count: attendances.length,
      attendances 
    });

  } catch (error) {
    console.error('Get Attendances Error:', error.message);
    res.status(500).json({ message: 'Failed to fetch attendances', error: error.message });
  }
};
