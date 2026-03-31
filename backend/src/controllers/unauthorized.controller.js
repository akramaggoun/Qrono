const prisma = require('../utils/prisma');

exports.getLogs = async (req, res) => {
  try {
    const { limit = 50, page = 1 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const logs = await prisma.unauthorizedAccessLog.findMany({
      take: parseInt(limit),
      skip: skip,
      include: {
        student: {
          include: {
            user: { select: { name: true, role: true } }
          }
        },
        session: { select: { courseName: true } },
        lab: { select: { name: true, roomNumber: true } }
      },
      orderBy: { occurredAt: 'desc' }
    });

    const total = await prisma.unauthorizedAccessLog.count();

    res.status(200).json({
      logs,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get Unauthorized Logs Error:', error.message);
    res.status(500).json({ message: 'Failed to fetch logs', error: error.message });
  }
};
