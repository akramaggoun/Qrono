const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

exports.getAllUsers = async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        role: true,
        isActive: true,
        createdAt: true,
        student: { select: { group: { select: { name: true } } } },
        professor: { select: { email: true } },
        admin: { select: { email: true } }
      }
    });
    res.status(200).json({ users });
  } catch (error) {
    res.status(500).json({ message: "Failed to fetch users", error: error.message });
  }
};

exports.createUser = async (req, res) => {
  const { name, password, role, email, groupId, studentCode, professorCode, department } = req.body;

  const validRole = role.toLowerCase(); 
  if (!['admin', 'professor', 'student'].includes(validRole)) {
    return res.status(400).json({ message: "Invalid role" });
  }

  try {
    let profileUniqueCheck = {};
    if (validRole === 'student') {
       if (!req.body.urn) return res.status(400).json({ message: "URN required for students" });
       const existing = await prisma.student.findUnique({ where: { urn: req.body.urn } });
       if (existing) return res.status(409).json({ message: "URN already used" });
    } else {
       if (!email) return res.status(400).json({ message: "Email required for this role" });
       const existing = validRole === 'professor' 
         ? await prisma.professor.findUnique({ where: { email } })
         : await prisma.admin.findUnique({ where: { email } });
       if (existing) return res.status(409).json({ message: "Email already used" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await prisma.$transaction(async (tx) => {
      const newUser = await tx.user.create({
        data: {
          name,
          password: hashedPassword,
          role: validRole,
          isActive: true,
        }
      });

      let profile;
      if (validRole === 'student') {
        profile = await tx.student.create({
          data: {
            userId: newUser.id,
            urn: req.body.urn,
            studentCode: studentCode,
            groupId: groupId || null
          }
        });
      } else if (validRole === 'professor') {
        profile = await tx.professor.create({
          data: {
            userId: newUser.id,
            email,
            professorCode,
            department
          }
        });
      } else if (validRole === 'admin') {
        profile = await tx.admin.create({
          data: {
            userId: newUser.id,
            email
          }
        });
      }

      return { user: newUser, profile };
    });

    res.status(201).json({ 
      user: { 
        id: result.user.id, 
        name: result.user.name, 
        role: result.user.role 
      },
      profile: result.profile
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Failed to create user", error: error.message });
  }
};

exports.updateUser = async (req, res) => {
  const { id } = req.params;
  const { name, isActive, groupId, role } = req.body;

  try {
    const updatedUser = await prisma.user.update({
      where: { id },
      data: { name, isActive, role: role ? role.toLowerCase() : undefined },
      select: { id: true, name: true, role: true, isActive: true }
    });

    if (groupId !== undefined) {
      await prisma.student.update({
        where: { userId: id },
        data: { groupId: groupId || null }
      }).catch(() => {});
    }

    res.status(200).json({ user: updatedUser });
  } catch (error) {
    res.status(500).json({ message: "Failed to update user", error: error.message });
  }
};

exports.deleteUser = async (req, res) => {
  const { id } = req.params;

  try {
    const user = await prisma.user.findUnique({
      where: { id },
      include: { student: true, professor: true }
    });

    if (!user) return res.status(404).json({ message: "User not found" });

    let hasRelatedRecords = false;

    if (user.professor) {
      const sessionCount = await prisma.session.count({
        where: { professorId: user.professor.id }
      });
      if (sessionCount > 0) hasRelatedRecords = true;
    }

    if (user.student && !hasRelatedRecords) {
      const attendanceCount = await prisma.attendance.count({
        where: { studentId: user.student.id }
      });
      if (attendanceCount > 0) hasRelatedRecords = true;
    }

    if (hasRelatedRecords) {
      await prisma.user.update({
        where: { id },
        data: { isActive: false }
      });
      return res.status(200).json({ message: "User deactivated" });
    } else {
      await prisma.user.delete({
        where: { id }
      });
      return res.status(200).json({ message: "User deleted successfully" });
    }
  } catch (error) {
    res.status(500).json({ message: "Failed to delete user", error: error.message });
  }
};
