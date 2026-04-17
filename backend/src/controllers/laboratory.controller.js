const prisma = require('../utils/prisma');

exports.getAllLaboratories = async (req, res) => {
  try {
    const labs = await prisma.laboratory.findMany({
      orderBy: [
        { building: 'asc' },
        { roomNumber: 'asc' }
      ]
    });

    res.status(200).json({ laboratories: labs });
  } catch (error) {
    console.error('Get Labs Error:', error.message);
    res.status(500).json({ message: 'Failed to fetch laboratories', error: error.message });
  }
};

exports.createLaboratory = async (req, res) => {
  const { name, building, roomNumber, capacity } = req.body;

  if (!name || !roomNumber) {
    return res.status(400).json({ message: 'Name and Room Number are required' });
  }

  try {
    const existing = await prisma.laboratory.findUnique({
      where: { roomNumber }
    });

    if (existing) {
      return res.status(409).json({ message: 'Room number already exists' });
    }

    const newLab = await prisma.laboratory.create({
      data: {
        name,
        building: building || null,
        roomNumber,
        capacity: capacity ? parseInt(capacity) : null,
        isActive: true
      }
    });

    res.status(201).json({ 
      message: 'Laboratory created successfully', 
      laboratory: newLab 
    });

  } catch (error) {
    console.error('Create Lab Error:', error.message);
    res.status(500).json({ message: 'Failed to create laboratory', error: error.message });
  }
};

exports.updateLaboratory = async (req, res) => {
  const { id } = req.params;
  const { name, building, roomNumber, capacity, isActive } = req.body;

  try {
    const existingLab = await prisma.laboratory.findUnique({ where: { id } });
    if (!existingLab) {
      return res.status(404).json({ message: 'Laboratory not found' });
    }

    if (roomNumber && roomNumber !== existingLab.roomNumber) {
      const conflict = await prisma.laboratory.findUnique({ where: { roomNumber } });
      if (conflict) {
        return res.status(409).json({ message: 'Room number already exists' });
      }
    }

    const updatedLab = await prisma.laboratory.update({
      where: { id },
      data: {
        name: name || existingLab.name,
        building: building !== undefined ? building : existingLab.building,
        roomNumber: roomNumber || existingLab.roomNumber,
        capacity: capacity !== undefined ? parseInt(capacity) : existingLab.capacity,
        isActive: isActive !== undefined ? isActive : existingLab.isActive
      }
    });

    res.status(200).json({ 
      message: 'Laboratory updated successfully', 
      laboratory: updatedLab 
    });

  } catch (error) {
    console.error('Update Lab Error:', error.message);
    if (error.code === 'P2025') {
      return res.status(404).json({ message: 'Laboratory not found' });
    }
    res.status(500).json({ message: 'Failed to update laboratory', error: error.message });
  }
};

exports.deleteLaboratory = async (req, res) => {
  const { id } = req.params;

  try {
    const lab = await prisma.laboratory.findUnique({ where: { id } });

    if (!lab) {
      return res.status(404).json({ message: 'Laboratory not found' });
    }

    await prisma.laboratory.update({
      where: { id },
      data: { isActive: false }
    });

    res.status(200).json({ 
      message: 'Laboratory deactivated successfully (Soft Delete)', 
      laboratory: { id, isActive: false } 
    });

  } catch (error) {
    console.error('Delete Lab Error:', error.message);
    res.status(500).json({ message: 'Failed to delete laboratory', error: error.message });
  }
};
