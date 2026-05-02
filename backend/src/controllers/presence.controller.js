const prisma = require('../utils/prisma');
const qrService = require('../services/qr.service');
const notificationService = require('../services/notification.service');

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
    // We don't have the student profile yet, so we fetch it to get the student record ID
    const studentProfile = await prisma.student.findUnique({
      where: { userId: req.user.id },
      select: { id: true }
    });
    
    await logUnauthorizedAttempt(studentProfile?.id || null, null, null, qr_token, 'Invalid or expired QR token');
    return res.status(401).json({ message: 'Invalid or expired QR code' });
  }

  const sessionId = decoded.sessionId;
  const studentId = req.user.id;

  try {
    const studentProfile = await prisma.student.findUnique({
      where: { userId: studentId },
      include: { user: { select: { name: true } } }
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
        lab: true,
        professor: { select: { userId: true } }
      }
    });

    if (!session) {
      await logUnauthorizedAttempt(studentProfile.id, sessionId, null, qr_token, 'Session not found');
      return res.status(404).json({ message: 'error_session_not_found' });
    }

    const qrRecord = session.qrCodes[0];

    // Sequence Diagram Step 4 : Check Revocation
    if (qrRecord && qrRecord.isRevoked) {
      await logUnauthorizedAttempt(studentProfile.id, sessionId, session.labId, qr_token, 'QR Code was revoked');
      return res.status(400).json({ message: 'error_qr_revoked' });
    }

    // Sequence Diagram Step 4 : Check Expiry
    const now = new Date();
    if (qrRecord) {
      if (now < qrRecord.validFrom || now > qrRecord.validUntil) {
        await logUnauthorizedAttempt(studentProfile.id, sessionId, session.labId, qr_token, 'QR Code expired');
        return res.status(400).json({ message: 'error_qr_expired' });
      }
    }

    // Sequence Diagram Step 5 : Check Session Status
    if (session.status !== 'ACTIVE') {
      await logUnauthorizedAttempt(studentProfile.id, sessionId, session.labId, qr_token, 'Session is not active');
      return res.status(400).json({ message: 'error_session_inactive' });
    }

    // Sequence Diagram Step 6 : Check Student Group
    if (studentProfile.groupId !== session.groupId) {
      await logUnauthorizedAttempt(
        studentProfile.id, 
        sessionId, 
        session.labId, 
        qr_token, 
        'Wrong group',
        session.professor.userId,
        studentProfile.user.name,
        session.courseName
      );
      return res.status(403).json({ message: "error_wrong_group" });
    }

    // Sequence Diagram Step 7 : Check Duplicate
    const existingAttendance = await prisma.attendance.findUnique({
      where: {
        sessionId_studentId: {
          sessionId,
          studentId: studentProfile.id
        }
      }
    });

    if (existingAttendance) {
      return res.status(409).json({ message: 'Already registered' });
    }

    // Sequence Diagram Step 8 : Record Attendance
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

    await notificationService.createAndSendNotification(req.user.id, {
      title: "✅ Registered presence",
      body: `Your attendance for ${attendance.session.courseName} has been validated`,
      type: "ATTENDANCE_RECORDED",
      data: { attendanceId: attendance.id, sessionId: sessionId }
    });

    // Check for "excessive absences" (5+)
    try {
      const allSessionsForCourse = await prisma.session.findMany({
        where: {
          groupId: studentProfile.groupId,
          courseName: session.courseName,
          status: 'CLOSED' // Only count officially finished ones? Or include ACTIVE?
        }
      });

      const studentAttendancesForCourse = await prisma.attendance.count({
        where: {
          studentId: studentProfile.id,
          session: { courseName: session.courseName }
        }
      });

      const absenceCount = allSessionsForCourse.length - studentAttendancesForCourse;

      if (absenceCount >= 5) {
        // Notify both student and professor
        await notificationService.createAndSendNotification(studentId, {
          title: "⚠️ Absence Warning",
          body: `Warning: You have reached ${absenceCount} absences in ${session.courseName}. You are at risk of exclusion.`,
          type: "warning",
          data: { courseName: session.courseName, absenceCount: absenceCount.toString() }
        });

        const professor = await prisma.professor.findUnique({
          where: { id: session.professorId },
          select: { userId: true }
        });

        if (professor) {
          await notificationService.createAndSendNotification(professor.userId, {
            title: "📢 Student Absence Alert",
            body: `Student ${studentProfile.user.name} has reached ${absenceCount} absences in ${session.courseName}.`,
            type: "warning",
            data: { studentId: studentProfile.id.toString(), courseName: session.courseName }
          });
        }
      }
    } catch (countErr) {
      console.error('Failed to check absence threshold:', countErr.message);
    }

    res.status(201).json({
      message: 'Attendance recorded successfully',
      attendance: {
        id: attendance.id,
        checkInAt: attendance.checkInAt,
        session: {
            courseName: session.courseName,
            laboratory: session.lab.name,
            group: session.group.name
        }
      }
    });

  } catch (error) {
    console.error('Scan QR Error:', error.message);
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

async function logUnauthorizedAttempt(studentId, sessionId, labId, scannedToken, reason, professorUserId, studentName, courseName) {
  try {
    const log = await prisma.unauthorizedAccessLog.create({
      data: {
        studentId,
        sessionId,
        labId,
        scannedToken,
        reason,
        occurredAt: new Date()
      }
    });

    // Sequence Diagram Step 6 : Notify Professor and Admins
    if (reason === 'Wrong group' && professorUserId) {
        // Notify Professor
        await notificationService.createAndSendNotification(professorUserId, {
            title: "notif_unauthorized_title",
            body: `notif_unauthorized_body|${studentName}|${courseName}`,
            type: "UNAUTHORIZED_ACCESS",
            data: { studentId, sessionId, reason }
        });

        // Notify Admins
        const admins = await prisma.admin.findMany({ select: { userId: true } });
        for (const admin of admins) {
            await notificationService.createAndSendNotification(admin.userId, {
                title: "notif_admin_alert_title",
                body: `notif_admin_alert_body|${courseName}`,
                type: "UNAUTHORIZED_ACCESS",
                data: { studentId, sessionId, reason }
            });
        }

        // Sequence Diagram Requirement: Update timestamps in log
        await prisma.unauthorizedAccessLog.update({
            where: { id: log.id },
            data: {
                professorNotifiedAt: new Date(),
                adminNotifiedAt: new Date()
            }
        });
    }
  } catch (err) {
    console.error('Failed to log unauthorized attempt:', err.message);
  }
}
