const prisma = require('../utils/prisma');
const qrService = require('../services/qr.service');

exports.scanQR = async (req, res) => {
  const { qr_token } = req.body;

  if (!qr_token) {
    return res.status(400).json({ message: 'QR token is required' });
  }

  if (req.user.role !== 'student') {
    return res.status(403).json({ message: 'Only students can scan for attendance' });
  }

  let decoded;
  try {
    decoded = qrService.validateQrToken(qr_token);
  } catch (err) {
    await logUnauthorizedAttempt(req.user.id, null, null, qr_token, 'Invalid or expired QR token');
    return res.status(401).json({ message: 'Invalid or expired QR code' });
  }

  const sessionId = decoded.sessionId;
  const studentId = req.user.id;

  try {
    const studentProfile = await prisma.student.findUnique({
      where: { userId: studentId },
      select: { id: true, groupId: true }
    });

    if (!studentProfile) {
      return res.status(404).json({ message: 'Student profile not found' });
    }

    const session = await prisma.session.findUnique({
      where: { id: sessionId },
      include: {
        qrCodes: {
          where: { token: qr_token },
          orderBy: { createdAt: 'desc' },
          take: 1
        },
        group: true,
        lab: true
      }
    });

    if (!session) {
      await logUnauthorizedAttempt(studentProfile.id, sessionId, null, qr_token, 'Session not found');
      return res.status(404).json({ message: 'Session not found' });
    }

    const qrRecord = session.qrCodes[0];

    if (qrRecord && qrRecord.isRevoked) {
      await logUnauthorizedAttempt(studentProfile.id, sessionId, session.labId, qr_token, 'QR Code was revoked (Session closed)');
      return res.status(403).json({ message: 'This QR code has been revoked. The session may be closed.' });
    }

    const now = new Date();
    if (qrRecord) {
      if (now < qrRecord.validFrom || now > qrRecord.validUntil) {
        await logUnauthorizedAttempt(studentProfile.id, sessionId, session.labId, qr_token, 'Scan outside valid time window');
        return res.status(403).json({ 
          message: 'Scan failed: Outside valid time window',
          details: `Valid from ${qrRecord.validFrom} to ${qrRecord.validUntil}`
        });
      }
    }

    if (now < session.startTime || now > session.endTime) {
      await prisma.unauthorizedAccessLog.create({
        data: {
          sessionId: session.id,
          studentId,
          labId: session.labId,
          reason: now < session.startTime ? 'SESSION_NOT_STARTED' : 'SESSION_ENDED',
          occurredAt: now
        }
      });

      return res.status(403).json({ 
        message: 'This session is not currently active.' 
      });
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
      return res.status(200).json({ 
        message: 'You have already checked in for this session',
        attendance: existingAttendance 
      });
    }

    const attendance = await prisma.attendance.create({
      data: {
        sessionId,
        studentId: studentProfile.id,
        qrCodeId: qrRecord ? qrRecord.id : null,
        checkInAt: now,
        method: 'qr'
      },
      include: {
        session: { select: { courseName: true } }
      }
    });

    res.status(201).json({
      message: 'Attendance recorded successfully',
      attendance: {
        id: attendance.id,
        courseName: attendance.session.courseName,
        checkInAt: attendance.checkInAt
      }
    });

  } catch (error) {
    console.error('Scan QR Error:', error.message);
    if (studentId) {
       const sProf = await prisma.student.findUnique({ where: { userId: studentId }});
       if(sProf) await logUnauthorizedAttempt(sProf.id, sessionId, null, qr_token, `System Error: ${error.message}`);
    }
    res.status(500).json({ message: 'Failed to process scan', error: error.message });
  }
};

exports.getMyAttendances = async (req, res) => {
  if (req.user.role !== 'student') {
    return res.status(403).json({ message: 'Only students can view their own attendance' });
  }

  try {
    const studentProfile = await prisma.student.findUnique({
      where: { userId: req.user.id },
      select: { id: true }
    });

    if (!studentProfile) {
      return res.status(404).json({ message: 'Student profile not found' });
    }

    const attendances = await prisma.attendance.findMany({
      where: { studentId: studentProfile.id },
      include: {
        session: {
          select: {
            courseName: true,
            startTime: true,
            endTime: true,
            lab: { select: { name: true, roomNumber: true } }
          }
        }
      },
      orderBy: { checkInAt: 'desc' }
    });

    res.status(200).json({ attendances });

  } catch (error) {
    console.error('Get My Attendances Error:', error.message);
    res.status(500).json({ message: 'Failed to fetch attendance history', error: error.message });
  }
};

async function logUnauthorizedAttempt(studentId, sessionId, labId, scannedToken, reason) {
  try {

    await prisma.unauthorizedAccessLog.create({
      data: {
        studentId,
        sessionId,
        labId,
        scannedToken,
        reason,
        occurredAt: new Date()
      }
    });
  } catch (err) {
    console.error('Failed to log unauthorized attempt:', err.message);
  }
}
