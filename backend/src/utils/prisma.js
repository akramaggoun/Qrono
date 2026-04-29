const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function autoCloseExpiredSessions() {
  const now = new Date();
  
  try {
    // FORCE UPDATE: Mark any ACTIVE session as CLOSED if its endTime has passed.
    // We do this precisely based on the database's Date objects.
    const result = await prisma.session.updateMany({
      where: {
        endTime: { lt: now },
        status: 'ACTIVE'
      },
      data: {
        status: 'CLOSED'
      }
    });

    if (result.count > 0) {
      console.log(`[Auto-Close] Force closed ${result.count} sessions at ${now.toISOString()}`);
    }
  } catch (error) {
    console.error('[Auto-Close Error]', error);
  }
}

module.exports = prisma;
module.exports.autoCloseExpiredSessions = autoCloseExpiredSessions;
