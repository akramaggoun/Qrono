const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const sessCount = await prisma.session.count();
  console.log('--- SESSION ANALYSIS ---');
  console.log('Total Global Sessions:', sessCount);

  const groups = await prisma.group.findMany({
    include: {
      _count: {
        select: { sessions: true }
      }
    }
  });

  groups.forEach(g => {
    console.log(`Group ${g.name}: ${g._count.sessions} sessions`);
  });
  console.log('------------------------');
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
