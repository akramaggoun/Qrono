const prisma = require('../utils/prisma');
const notificationService = require('../services/notification.service');
const qrService = require('../services/qr.service');

// ---------- CRUD ----------

/** Admin creates a schedule (container for sessions) */
exports.createSchedule = async (req, res) => {
  const { name, description, professorId, recurrence } = req.body;

  if (!name || !professorId) {
    return res.status(400).json({ message: 'Name and professorId are required' });
  }

  try {
    // Verify the admin profile exists
    const adminProfile = await prisma.admin.findUnique({ where: { userId: req.user.id } });
    if (!adminProfile) return res.status(403).json({ message: 'Only admins can create schedules' });

    // Verify the professor exists
    const professor = await prisma.professor.findUnique({ where: { id: professorId } });
    if (!professor) return res.status(404).json({ message: 'Professor not found' });

    const schedule = await prisma.schedule.create({
      data: {
        name,
        description,
        createdByAdminId: adminProfile.userId,
        professorId,
        // If you add a JSON 'recurrence' column to Schedule, store it here:
        // recurrence: recurrence ?? null,
      },
      include: { professor: { select: { id: true, user: { select: { name: true } } } } },
    });

    res.status(201).json({ message: 'Schedule created', schedule });
  } catch (error) {
    console.error('createSchedule error:', error);
    res.status(500).json({ message: 'Failed to create schedule', error: error.message });
  }
};

/** Admin lists all schedules (or filter by professor) */
exports.getAllSchedules = async (req, res) => {
  try {
    const { professorId } = req.query;
    const where = professorId ? { professorId } : {};
    const schedules = await prisma.schedule.findMany({
      where,
      include: {
        professor: { select: { id: true, user: { select: { name: true } } } },
        _count: { select: { sessions: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ schedules });
  } catch (error) {
    console.error('getAllSchedules error:', error);
    res.status(500).json({ message: 'Failed to fetch schedules', error: error.message });
  }
};

/** Get a single schedule with its sessions */
exports.getScheduleById = async (req, res) => {
  const { id } = req.params;
  try {
    const schedule = await prisma.schedule.findUnique({
      where: { id },
      include: {
        sessions: {
          include: {
            lab: { select: { name: true } },
            group: { select: { name: true } },
          },
          orderBy: { startTime: 'asc' },
        },
      },
    });
    if (!schedule) return res.status(404).json({ message: 'Schedule not found' });
    res.json({ schedule });
  } catch (error) {
    console.error('getScheduleById error:', error);
    res.status(500).json({ message: 'Failed to fetch schedule', error: error.message });
  }
};

/** Admin updates schedule metadata */
exports.updateSchedule = async (req, res) => {
  const { id } = req.params;
  const { name, description, isActive } = req.body;
  try {
    const schedule = await prisma.schedule.update({
      where: { id },
      data: { name, description, isActive },
    });
    res.json({ message: 'Schedule updated', schedule });
  } catch (error) {
    console.error('updateSchedule error:', error);
    res.status(500).json({ message: 'Failed to update schedule', error: error.message });
  }
};

/** Admin deletes a schedule (cascades set to SetNull on sessions, so sessions stay) */
exports.deleteSchedule = async (req, res) => {
  const { id } = req.params;
  try {
    await prisma.schedule.delete({ where: { id } });
    res.json({ message: 'Schedule deleted – sessions are not deleted' });
  } catch (error) {
    console.error('deleteSchedule error:', error);
    res.status(500).json({ message: 'Failed to delete schedule', error: error.message });
  }
};

// ---------- SESSION GENERATION ----------

/**
 * Given a schedule with a recurrence rule, generate all sessions for that schedule.
 * This is an example – you can adapt the recurrence format to your needs.
 */
exports.generateSessionsFromSchedule = async (req, res) => {
  const { id: scheduleId } = req.params;
  // recurrence format example: { days: ['MON','WED'], startDate:'2025-09-01', endDate:'2025-12-20', startTime:'08:00', endTime:'10:00' }
  const { recurrence } = req.body;  

  if (!recurrence) {
    return res.status(400).json({ message: 'Recurrence object required' });
  }

  try {
    const schedule = await prisma.schedule.findUnique({
      where: { id: scheduleId },
      include: { professor: true },
    });
    if (!schedule) return res.status(404).json({ message: 'Schedule not found' });

    // You'll need a helper that expands the recurrence into concrete dates
    const sessionDates = expandRecurrence(recurrence); // implement this helper

    const createdSessions = [];
    for (const { start, end } of sessionDates) {
      const session = await prisma.session.create({
        data: {
          courseName: schedule.name,
          startTime: start,
          endTime: end,
          scheduleId: schedule.id,
          professorId: schedule.professorId,
          groupId: req.body.groupId,         // must be provided
          labId: req.body.labId,             // must be provided
          status: 'ACTIVE',
        },
      });
      createdSessions.push(session);
    }

    res.status(201).json({ message: `Generated ${createdSessions.length} sessions`, sessions: createdSessions });
  } catch (error) {
    console.error('generateSessions error:', error);
    res.status(500).json({ message: 'Failed to generate sessions', error: error.message });
  }
};

function expandRecurrence({ days, startTime, endTime, startDate, endDate }) {
  const results = [];
  const dayMap = { SUN: 0, MON: 1, TUE: 2, WED: 3, THU: 4, FRI: 5, SAT: 6 };
  const dayNumbers = days.map(d => dayMap[d]);

  const current = new Date(startDate);
  const last = new Date(endDate);

  while (current <= last) {
    if (dayNumbers.includes(current.getDay())) {
      // Build the exact start datetime for this day
      const [sh, sm] = startTime.split(':').map(Number);
      const sessionStart = new Date(current);
      sessionStart.setHours(sh, sm, 0, 0);

      const [eh, em] = endTime.split(':').map(Number);
      const sessionEnd = new Date(current);
      sessionEnd.setHours(eh, em, 0, 0);

      results.push({ start: sessionStart, end: sessionEnd });
    }
    // Move to next day
    current.setDate(current.getDate() + 1);
  }
  return results;
}
