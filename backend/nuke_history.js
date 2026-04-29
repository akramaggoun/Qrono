const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function nukeHistory() {
  try {
    console.log('--- NUKING ATTENDANCE AND LOG HISTORY ---');
    
    // Using transation to ensure all or nothing
    await prisma.$transaction([
      prisma.attendance.deleteMany({}),
      prisma.unauthorizedAccessLog.deleteMany({}),
      prisma.exclusion.deleteMany({})
    ]);

    console.log('✓ Attendance records cleared');
    console.log('✓ Unauthorized logs cleared');
    console.log('✓ Exclusion records cleared');
    console.log('--- HISTORY NUKED SUCCESSFULLY ---');
  } catch (err) {
    console.error('Error nuking history:', err);
  } finally {
    await prisma.$disconnect();
  }
}

nukeHistory();
