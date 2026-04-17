require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const qrService = require('./src/services/qr.service');
const prisma = new PrismaClient();

async function createTestSession() {
  console.log('⏳ Creating active test session with REAL SIGNED QR TOKEN...');
  
  try {
    const prof = await prisma.professor.findFirst();
    const lab = await prisma.laboratory.findFirst({ where: { isActive: true } });
    const group = await prisma.group.findFirst();

    if (!prof || !lab || !group) throw new Error('Missing seed data');

    const now = new Date();
    const startTime = new Date(now.getTime() - (5 * 60000));
    const endTime = new Date(now.getTime() + (120 * 60000));

    // Create session
    const session = await prisma.session.create({
      data: {
        courseName: 'REAL QR TEST',
        startTime: startTime,
        endTime: endTime,
        status: 'ACTIVE',
        professorId: prof.id,
        labId: lab.id,
        groupId: group.id
      }
    });

    // Generate REAL JWT TOKEN via the app's service
    const jwtToken = qrService.createQrToken(session.id, endTime);

    // Create QR record with the JWT
    const qr = await prisma.qrCode.create({
      data: {
        sessionId: session.id,
        token: jwtToken,
        validFrom: startTime,
        validUntil: endTime,
        isRevoked: false
      }
    });

    console.log('\n✅ SESSION READY - VALID JWT GENERATED');
    console.log('------------------------------------');
    console.log(`Course: ${session.courseName}`);
    console.log(`QR Token (JWT): ${qr.token.substring(0, 50)}...`);
    console.log(`Session ID: ${session.id}`);
    console.log('------------------------------------');
    console.log('\n📱 TEST INSTRUCTIONS:');
    console.log('1. Open the Student App.');
    console.log('2. Perform a Scan.');
    console.log('3. The backend will now VALIDATE the JWT successfully.');
    
  } catch (error) {
    console.error('❌ Failed:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

createTestSession();
