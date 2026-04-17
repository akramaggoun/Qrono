const { verifyUserToken } = require('../utils/jwt');

const prisma = require('../utils/prisma');

const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Access denied: No token provided' });
    }

    const token = authHeader.split(' ')[1];

    let decoded;
    try {
      decoded = verifyUserToken(token);
    } catch (err) {
      return res.status(401).json({ message: 'Invalid or expired token' });
    }

    if (!decoded || !decoded.id) {
      return res.status(401).json({ message: 'Invalid token payload' });
    }

    const user = await prisma.user.findUnique({
      where: { id: decoded.id },
      include: {
        professor: { select: { id: true } },
        student: { select: { id: true } },
        admin: { select: { id: true } }
      }
    });

    if (!user) {
      return res.status(401).json({ message: 'User not found' });
    }

    if (!user.isActive) {
      return res.status(403).json({ message: 'Account deactivated. Please contact support.' });
    }

    // Attach role-specific IDs directly to req.user for convenience
    req.user = {
      ...user,
      professorId: user.professor?.id,
      studentId: user.student?.id,
      adminId: user.admin?.id
    };
    next();

  } catch (error) {
    console.error('Auth Middleware Error:', error.message);
    return res.status(500).json({ message: 'Internal server error during authentication' });
  }
};

module.exports = authMiddleware;
