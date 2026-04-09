const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function check() {
  const admins = await prisma.admin.findMany({ select: { email: true, userId: true } });
  const profs = await prisma.professor.findMany({ select: { email: true, userId: true } });
  const users = await prisma.user.findMany({ select: { id: true, role: true, isActive: true } });
  
  console.log('--- ADMINS ---');
  console.log(admins);
  console.log('--- PROFS ---');
  console.log(profs);
  console.log('--- USERS ---');
  console.log(users);
  process.exit(0);
}

check();
