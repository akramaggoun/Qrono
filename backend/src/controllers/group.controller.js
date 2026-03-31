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
        { yearLevel: 'asc' },
        { name: 'asc' }
      ]
    });

    res.status(200).json({ groups });
  } catch (error) {
    console.error('Get Groups Error:', error.message);
    res.status(500).json({ message: 'Failed to fetch groups', error: error.message });
  }
};

exports.createGroup = async (req, res) => {
  const { name, yearLevel } = req.body;

  if (!name) {
    return res.status(400).json({ message: 'Group name is required' });
  }

  try {
    const newGroup = await prisma.group.create({
      data: {
        name,
        yearLevel: yearLevel ? parseInt(yearLevel) : null
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
  const { name, yearLevel } = req.body;

  try {
    const existingGroup = await prisma.group.findUnique({ where: { id } });
    if (!existingGroup) {
      return res.status(404).json({ message: 'Group not found' });
    }

    const updatedGroup = await prisma.group.update({
      where: { id },
      data: {
        name: name || existingGroup.name,
        yearLevel: yearLevel !== undefined ? parseInt(yearLevel) : existingGroup.yearLevel
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

    if (group._count.students > 0) {
      return res.status(409).json({ 
        message: `Cannot delete group. ${group._count.students} student(s) are still assigned to this group. Please unassign them first.` 
      });
    }

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
