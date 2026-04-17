const prisma = require('../utils/prisma');

exports.getAllSchedules = async (req, res) => {
  try {
    const { role, professorId } = req.user;
    let whereClause = {};

    if (role === 'professor') {
      whereClause = { professorId: professorId, isActive: true };
    }

    const schedules = await prisma.schedule.findMany({
      where: whereClause,
      include: {
        professor: {
          include: { user: { select: { name: true } } }
        },
        group: {
          select: { id: true, name: true }
        },
        lab: {
          select: { id: true, name: true }
        },
        createdByAdmin: {
          select: { name: true }
        },
        _count: {
          select: { sessions: true }
        }
      },
      orderBy: [
        { createdAt: 'desc' }
      ]
    });

    res.status(200).json({ schedules });
  } catch (error) {
    console.error('Get Schedules Error:', error.message);
    res.status(500).json({ message: 'Failed to fetch schedules', error: error.message });
  }
};

exports.createSchedule = async (req, res) => {
  console.log('📥 CREATE SCHEDULE REQUEST:', req.body);
  let { name, description, professorId, groupId, labId, dayOfWeek, startTime, endTime, isActive } = req.body;
  const createdByAdminId = req.user.id;

  if (!name || !professorId) {
    return res.status(400).json({ message: 'Name and Professor ID are required' });
  }

  try {
    // ID RESOLUTION: Check if professorId is actually a userId
    const profRecord = await prisma.professor.findFirst({
      where: {
        OR: [
          { id: professorId },
          { userId: professorId }
        ]
      }
    });

    if (!profRecord) {
      return res.status(404).json({ message: 'Professor profile not found' });
    }

    // Use the actual professor.id
    professorId = profRecord.id;

    const newSchedule = await prisma.schedule.create({
      data: {
        name,
        description: description || null,
        professorId,
        groupId: groupId || null,
        labId: labId || null,
        dayOfWeek: dayOfWeek ? parseInt(dayOfWeek) : null,
        startTime: startTime || null,
        endTime: endTime || null,
        createdByAdminId,
        isActive: isActive !== undefined ? isActive : true
      },
      include: {
        professor: {
          include: { user: { select: { name: true } } }
        },
        group: {
          select: { name: true }
        },
        lab: {
          select: { name: true }
        }
      }
    });

    res.status(201).json({ 
      message: 'Schedule created successfully', 
      schedule: newSchedule 
    });

  } catch (error) {
    console.error('Create Schedule Error:', error.message);
    res.status(500).json({ message: 'Failed to create schedule', error: error.message });
  }
};

exports.updateSchedule = async (req, res) => {
  const { id } = req.params;
  let { name, description, professorId, groupId, labId, dayOfWeek, startTime, endTime, isActive } = req.body;

  try {
    const existingSchedule = await prisma.schedule.findUnique({ where: { id } });
    if (!existingSchedule) {
      return res.status(404).json({ message: 'Schedule not found' });
    }

    if (professorId) {
      const profRecord = await prisma.professor.findFirst({
        where: {
          OR: [
            { id: professorId },
            { userId: professorId }
          ]
        }
      });
      if (profRecord) {
        professorId = profRecord.id;
      }
    }

    const updatedSchedule = await prisma.schedule.update({
      where: { id },
      data: {
        name: name || existingSchedule.name,
        description: description !== undefined ? description : existingSchedule.description,
        professorId: professorId || existingSchedule.professorId,
        groupId: groupId !== undefined ? (groupId || null) : existingSchedule.groupId,
        labId: labId !== undefined ? (labId || null) : existingSchedule.labId,
        dayOfWeek: dayOfWeek !== undefined ? (dayOfWeek ? parseInt(dayOfWeek) : null) : existingSchedule.dayOfWeek,
        startTime: startTime !== undefined ? (startTime || null) : existingSchedule.startTime,
        endTime: endTime !== undefined ? (endTime || null) : existingSchedule.endTime,
        isActive: isActive !== undefined ? isActive : existingSchedule.isActive
      },
      include: {
        professor: {
          include: { user: { select: { name: true } } }
        },
        group: {
          select: { name: true }
        },
        lab: {
          select: { name: true }
        }
      }
    });

    res.status(200).json({ 
      message: 'Schedule updated successfully', 
      schedule: updatedSchedule 
    });

  } catch (error) {
    console.error('Update Schedule Error:', error.message);
    res.status(500).json({ message: 'Failed to update schedule', error: error.message });
  }
};

exports.deleteSchedule = async (req, res) => {
  const { id } = req.params;

  try {
    const schedule = await prisma.schedule.findUnique({ where: { id } });

    if (!schedule) {
      return res.status(404).json({ message: 'Schedule not found' });
    }

    await prisma.schedule.delete({
      where: { id }
    });

    res.status(200).json({ 
      message: 'Schedule deleted successfully', 
      schedule: { id } 
    });

  } catch (error) {
    console.error('Delete Schedule Error:', error.message);
    res.status(500).json({ message: 'Failed to delete schedule', error: error.message });
  }
};
