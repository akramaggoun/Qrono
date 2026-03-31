const prisma = require('../utils/prisma');
const bcrypt = require('bcryptjs');
const { generateUserToken } = require('../utils/jwt');

exports.login = async (req, res) => {
  const { matricule, password } = req.body;

  if (!matricule || !password) {
    return res.status(400).json({ message: 'Matricule and password are required' });
  }

  try {
    let userId = null;

    const student = await prisma.student.findUnique({ 
      where: { urn: matricule } 
    });
    
    if (student) {
      userId = student.userId;
    } else {
      const professor = await prisma.professor.findUnique({ 
        where: { email: matricule } 
      });
      
      if (professor) {
        userId = professor.userId;
      } else {
        const admin = await prisma.admin.findUnique({ 
          where: { email: matricule } 
        });
        if (admin) {
          userId = admin.userId;
        }
      }
    }

    if (!userId) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { 
        id: true, 
        password: true, 
        role: true, 
        isActive: true, 
        name: true 
      }
    });

    if (!user || !user.isActive) {
      return res.status(403).json({ message: 'Account inactive or not found' });
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = generateUserToken({
      id: user.id,
      role: user.role
    }, '24h');

    res.status(200).json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        name: user.name,
        role: user.role
      }
    });

  } catch (error) {
    console.error('Login Error:', error.message);
    res.status(500).json({ message: 'Server error during login' });
  }
};
