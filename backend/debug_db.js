const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('--- USERS ---');
  const users = await prisma.user.findMany({ select: { id: true, name: true, role: true } });
  console.log(JSON.stringify(users, null, 2));

  console.log('\n--- SCHEDULES ---');
  const schedules = await prisma.schedule.findMany({ include: { sessions: true } });
  console.log(JSON.stringify(schedules, null, 2));

  console.log('\n--- SESSIONS ---');
  const sessions = await prisma.session.findMany({ include: { professor: true } });
  console.log(JSON.stringify(sessions, null, 2));
}

main().catch(e => console.error(e)).finally(() => prisma.$disconnect());
