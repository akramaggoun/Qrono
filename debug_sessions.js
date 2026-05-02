const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function check() {
  try {
    const sessCount = await prisma.session.count();
    const groups = await prisma.group.findMany({ include: { _count: { select: { sessions: true } } } });
    console.log('--- SESSION ANALYSIS ---');
    console.log('Total Global Sessions:', sessCount);
    groups.forEach(g => { console.log('Group ' + g.name + ': ' + g._count.sessions + ' sessions'); });
    console.log('------------------------');
  } catch (e) {
    console.error(e);
  } finally {
    await prisma['']();
  }
}
check();