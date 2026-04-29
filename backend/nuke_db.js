const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('--- STARTING TOTAL DATABASE CLEANUP ---');
  try {
    // Order matters for foreign keys
    await prisma.attendance.deleteMany();
    console.log('✓ Attendance cleared');
    
    await prisma.qrCode.deleteMany();
    console.log('✓ QR Codes cleared');
    
    await prisma.session.deleteMany();
    console.log('✓ Sessions cleared');
    
    await prisma.student.deleteMany();
    console.log('✓ Students cleared');
    
    await prisma.professor.deleteMany();
    console.log('✓ Professors cleared');
    
    await prisma.admin.deleteMany();
    console.log('✓ Admins cleared');
    
    await prisma.user.deleteMany();
    console.log('✓ Users cleared');
    
    await prisma.group.deleteMany();
    console.log('✓ Groups cleared');
    
    await prisma.laboratory.deleteMany();
    console.log('✓ Laboratories cleared');

    console.log('--- DATABASE CLEANED SUCCESSFULLY ---');
  } catch (error) {
    console.error('--- CLEANUP FAILED ---');
    console.error(error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
