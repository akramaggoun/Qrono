/**
 * Qrono Notification Test Script
 *
 * Usage:
 *   node test_notification.js              -> send to all users
 *   node test_notification.js <userId>     -> send to specific user
 *   node test_notification.js list         -> list all users
 */

const dotenv = require('dotenv');
dotenv.config();

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const TEST_NOTIFICATIONS = [
  {
    type: 'session_started',
    title: 'Session Started',
    body: 'A new attendance session has started in Lab A101. Mark your attendance now.',
    data: { laboratoryId: 'test-lab-1', sessionId: 'test-session-1' }
  },
  {
    type: 'absence_warning',
    title: 'Absence Warning',
    body: 'You have 3 absences in the Database course. Further absences may affect your grade.',
    data: { subjectName: 'Database' }
  },
  {
    type: 'schedule_update',
    title: 'Schedule Updated',
    body: 'Your group schedule has been updated for next week. Please check the new timetable.',
    data: { groupId: 'test-group-1' }
  },
  {
    type: 'qr_generated',
    title: 'QR Code Ready',
    body: 'A new QR code has been generated for the current session. Open the app to scan.',
    data: {}
  }
];

async function listUsers() {
  const users = await prisma.user.findMany({
    select: { id: true, name: true, role: true },
    take: 20
  });

  console.log('\nUsers in database:');
  console.log('===============================================');
  users.forEach((u, i) => {
    console.log(`  [${i + 1}] ${u.name} | ${u.role} | ID: ${u.id}`);
  });
  console.log('===============================================');
  console.log('\nTo send a notification to a specific user:');
  console.log('   node test_notification.js <userId>\n');
}

async function sendNotification(userId, notif) {
  try {
    await prisma.notification.create({
      data: {
        userId,
        type: notif.type,
        title: notif.title,
        body: notif.body,
        data: notif.data || {},
        isRead: false
      }
    });
    console.log(`  OK: "${notif.title}" -> [${userId.substring(0, 8)}...]`);
  } catch (e) {
    console.log(`  FAIL: ${e.message}`);
  }
}

async function main() {
  const arg = process.argv[2];

  console.log('\nQrono - Notification Test');
  console.log('===============================================\n');

  if (arg === 'list') {
    await listUsers();
    return;
  }

  if (arg) {
    const user = await prisma.user.findUnique({
      where: { id: arg },
      select: { id: true, name: true, role: true }
    });

    if (!user) {
      console.log(`User "${arg}" not found.`);
      console.log('Use: node test_notification.js list\n');
      return;
    }

    console.log(`Sending notifications to: ${user.name} (${user.role})\n`);

    for (const notif of TEST_NOTIFICATIONS) {
      await sendNotification(user.id, notif);
      await new Promise(r => setTimeout(r, 200));
    }

    console.log(`\nDone. ${TEST_NOTIFICATIONS.length} test notifications sent.`);
    console.log('Open the app and check the notifications section.\n');

  } else {
    const users = await prisma.user.findMany({
      select: { id: true, name: true, role: true },
      take: 10
    });

    console.log(`Sending to ${users.length} users...\n`);

    for (const user of users) {
      console.log(`\nUser: ${user.name} (${user.role}):`);
      const randomNotif = TEST_NOTIFICATIONS[Math.floor(Math.random() * TEST_NOTIFICATIONS.length)];
      await sendNotification(user.id, randomNotif);
    }

    console.log('\nDone. Open the app and check notifications.\n');
  }
}

main()
  .catch(e => {
    console.error('Error:', e.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
