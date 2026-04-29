const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const sessions = await prisma.session.findMany({
    where: {
      startTime: {
        gte: new Date('2026-04-26T00:00:00Z'),
        lt: new Date('2026-04-27T00:00:00Z')
      }
    },
    include: {
      lab: true,
      professor: { include: { user: true } }
    }
  });
  console.log(JSON.stringify(sessions, null, 2));
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
