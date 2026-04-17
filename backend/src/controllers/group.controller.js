const prisma = require('../utils/prisma');

exports.getAllGroups = async (req, res) => {
  try {
    const groups = await prisma.group.findMany({
      include: {
        _count: {
          select: { students: true }
        }
      },
      orderBy: [
        { name: 'asc' }
      ]
    });

    res.status(200).json({ groups });
  } catch (error) {
    console.error('Get Groups Error:', error.message);
    res.status(500).json({ message: 'Failed to fetch groups', error: error.message });
  }
};

exports.getGroupStudents = async (req, res) => {
  const { id } = req.params;
  try {
    const group = await prisma.group.findUnique({
      where: { id },
      include: {
        students: {
          include: {
            user: {
              select: { id: true, name: true, isActive: true }
            }
          }
        }
      }
    });

    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    res.status(200).json({ students: group.students });
  } catch (error) {
    console.error('Get Group Students Error:', error.message);
    res.status(500).json({ message: 'Failed to fetch group students', error: error.message });
  }
};

exports.createGroup = async (req, res) => {
  console.log('📥 CREATE GROUP REQUEST:', req.body);
  const { name, year_level, specialty } = req.body;
  const yearLevel = year_level;

  if (!name) {
    return res.status(400).json({ message: 'Group name is required' });
  }

  try {
    const newGroup = await prisma.group.create({
      data: {
        name,
        yearLevel: yearLevel || null,
        specialty: specialty || null
      }
    });

    res.status(201).json({ 
      message: 'Group created successfully', 
      group: newGroup 
    });

  } catch (error) {
    console.error('Create Group Error:', error.message);
    res.status(500).json({ message: 'Failed to create group', error: error.message });
  }
};

exports.updateGroup = async (req, res) => {
  const { id } = req.params;
  const { name, year_level, specialty } = req.body;
  const yearLevel = year_level;

  try {
    const existingGroup = await prisma.group.findUnique({ where: { id } });
    if (!existingGroup) {
      return res.status(404).json({ message: 'Group not found' });
    }

    const updatedGroup = await prisma.group.update({
      where: { id },
      data: {
        name: name || existingGroup.name,
        yearLevel: yearLevel !== undefined ? yearLevel : existingGroup.yearLevel,
        specialty: specialty !== undefined ? specialty : existingGroup.specialty
      }
    });

    res.status(200).json({ 
      message: 'Group updated successfully', 
      group: updatedGroup 
    });

  } catch (error) {
    console.error('Update Group Error:', error.message);
    if (error.code === 'P2025') {
      return res.status(404).json({ message: 'Group not found' });
    }
    res.status(500).json({ message: 'Failed to update group', error: error.message });
  }
};

exports.deleteGroup = async (req, res) => {
  const { id } = req.params;

  try {
    const group = await prisma.group.findUnique({
      where: { id },
      include: {
        _count: { select: { students: true } }
      }
    });

    if (!group) {
      return res.status(404).json({ message: 'Group not found' });
    }

    // The safety check was removed to allow force deleting the group.
    // Prisma will automatically set groupId to null for students in this group (onDelete: SetNull).

    await prisma.group.delete({
      where: { id }
    });

    res.status(200).json({ 
      message: 'Group deleted successfully', 
      group: { id } 
    });

  } catch (error) {
    console.error('Delete Group Error:', error.message);
    if (error.code === 'P2025') {
      return res.status(404).json({ message: 'Group not found' });
    }
    res.status(500).json({ message: 'Failed to delete group', error: error.message });
  }
};
