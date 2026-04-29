const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seeding...');

  // 1. CLEAR EXISTING DATA (Reverse order of dependencies)
  console.log('🧹 Clearing existing data...');
  await prisma.attendance.deleteMany();
  await prisma.unauthorizedAccessLog.deleteMany();
  await prisma.notification.deleteMany();
  await prisma.qrCode.deleteMany();
  await prisma.session.deleteMany();
  await prisma.student.deleteMany();
  await prisma.professor.deleteMany();
  await prisma.admin.deleteMany();
  await prisma.user.deleteMany();
  await prisma.laboratory.deleteMany();
  await prisma.group.deleteMany();

  // 2. CREATE ADMIN
  const adminPassword = await bcrypt.hash('Admin@1234', 10);
  const adminUser = await prisma.user.create({
    data: {
      name: 'Administrateur Qrono',
      password: adminPassword,
      role: 'admin',
      admin: {
        create: {
          email: 'admin@univ-khenchela.dz',
        },
      },
    },
  });
  console.log('✅ Admin created');

  // 3. CREATE PROFESSORS
  const profPassword = await bcrypt.hash('Prof@1234', 10);
  const profsData = [
    { name: 'Dr. Ahmed Benali', email: 'ahmed.benali@univ-khenchela.dz', code: 'PROF001', dept: 'Informatique' },
    { name: 'Dr. Sara Mansouri', email: 'sara.mansouri@univ-khenchela.dz', code: 'PROF002', dept: 'Réseaux' },
    { name: 'Dr. Karim Boudiaf', email: 'karim.boudiaf@univ-khenchela.dz', code: 'PROF003', dept: 'Systèmes' },
  ];

  const profs = [];
  for (const p of profsData) {
    const prof = await prisma.user.create({
      data: {
        name: p.name,
        password: profPassword,
        role: 'professor',
        professor: {
          create: {
            email: p.email,
            professorCode: p.code,
            department: p.dept,
          },
        },
      },
      include: { professor: true },
    });
    profs.push(prof.professor);
  }
  console.log('✅ Professors created (3)');

  // 4. CREATE GROUPS
  const groupsData = [
    { name: 'L3 Info G1', year: '3' },
    { name: 'L3 Info G2', year: '3' },
    { name: 'M1 Réseau', year: '4' },
    { name: 'M2 Systèmes', year: '5' },
  ];

  const groups = {};
  for (const g of groupsData) {
    const group = await prisma.group.create({
      data: {
        name: g.name,
        yearLevel: g.year,
      },
    });
    groups[g.name] = group;
  }
  console.log('✅ Groups created (4)');

  // 5. CREATE STUDENTS
  const studentPassword = await bcrypt.hash('Student@1234', 10);
  const studentsData = [
    { name: 'Khaled Amrani', urn: '20230001', code: 'STD001', group: 'L3 Info G1' },
    { name: 'Fatima Zerrouki', urn: '20230002', code: 'STD002', group: 'L3 Info G1' },
    { name: 'Yacine Hadj', urn: '20230003', code: 'STD003', group: 'L3 Info G2' },
    { name: 'Amira Bensalem', urn: '20230004', code: 'STD004', group: 'L3 Info G2' },
    { name: 'Mohamed Chaoui', urn: '20230005', code: 'STD005', group: 'M1 Réseau' },
    { name: 'Nour Belkacem', urn: '20230006', code: 'STD006', group: 'M1 Réseau' },
    { name: 'Riad Khelifi', urn: '20230007', code: 'STD007', group: 'M2 Systèmes' },
    { name: 'Lyna Ferhat', urn: '20230008', code: 'STD008', group: 'M2 Systèmes' },
  ];

  const students = {};
  for (const s of studentsData) {
    const student = await prisma.user.create({
      data: {
        name: s.name,
        password: studentPassword,
        role: 'student',
        student: {
          create: {
            urn: s.urn,
            studentCode: s.code,
            groupId: groups[s.group].id,
          },
        },
      },
      include: { student: true },
    });
    students[s.name] = student.student;
  }
  console.log('✅ Students created (8)');

  // 6. CREATE LABORATORIES
  const labsData = [
    { name: 'Laboratoire Informatique', bldg: 'Bloc A', room: 'A101', cap: 30, active: true },
    { name: 'Laboratoire Réseaux', bldg: 'Bloc A', room: 'A102', cap: 25, active: true },
    { name: 'Laboratoire Systèmes', bldg: 'Bloc B', room: 'B201', cap: 20, active: true },
    { name: 'Laboratoire Base de Données', bldg: 'Bloc B', room: 'B202', cap: 25, active: false },
  ];

  const labs = {};
  for (const l of labsData) {
    const lab = await prisma.laboratory.create({
      data: {
        name: l.name,
        building: l.bldg,
        roomNumber: l.room,
        capacity: l.cap,
        isActive: l.active,
      },
    });
    labs[l.name] = lab;
  }
  console.log('✅ Laboratories created (4)');

  // 7. SESSIONS & ATTENDANCE (Disabled - all stats start at 0)
  /*
  const today = new Date();
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);

  const sessionsData = [
    {
      course: 'TP Algorithmique',
      profEmail: 'ahmed.benali@univ-khenchela.dz',
      lab: 'Laboratoire Informatique',
      group: 'L3 Info G1',
      start: new Date(today.setHours(8, 0, 0, 0)),
      end: new Date(today.setHours(10, 0, 0, 0)),
      status: 'ACTIVE',
    },
    {
      course: 'TP Réseaux',
      profEmail: 'sara.mansouri@univ-khenchela.dz',
      lab: 'Laboratoire Réseaux',
      group: 'M1 Réseau',
      start: new Date(today.setHours(10, 0, 0, 0)),
      end: new Date(today.setHours(12, 0, 0, 0)),
      status: 'ACTIVE',
    },
    {
      course: 'TP Systèmes d\'exploitation',
      profEmail: 'karim.boudiaf@univ-khenchela.dz',
      lab: 'Laboratoire Systèmes',
      group: 'M2 Systèmes',
      start: new Date(yesterday.setHours(14, 0, 0, 0)),
      end: new Date(yesterday.setHours(16, 0, 0, 0)),
      status: 'CLOSED',
    },
  ];

  const sessions = {};
  for (const s of sessionsData) {
    const prof = await prisma.professor.findUnique({ where: { email: s.profEmail } });
    const session = await prisma.session.create({
      data: {
        courseName: s.course,
        startTime: s.start,
        endTime: s.end,
        status: s.status,
        professorId: prof.id,
        labId: labs[s.lab].id,
        groupId: groups[s.group].id,
      },
    });
    sessions[s.course] = session;
  }
  console.log('✅ Sessions created (3)');

  // 8. CREATE ATTENDANCE RECORDS
  const attendanceData = [
    { student: 'Khaled Amrani', session: 'TP Algorithmique', method: 'qr' },
    { student: 'Fatima Zerrouki', session: 'TP Algorithmique', method: 'qr' },
    { student: 'Mohamed Chaoui', session: 'TP Réseaux', method: 'qr' },
    { student: 'Riad Khelifi', session: 'TP Systèmes d\'exploitation', method: 'manual' },
  ];

  for (const a of attendanceData) {
    await prisma.attendance.create({
      data: {
        studentId: students[a.student].id,
        sessionId: sessions[a.session].id,
        method: a.method,
        status: 'present'
      },
    });
  }
  console.log('✅ Attendance records created (4)');
  */
  console.log('ℹ️ Session and Attendance creation bypassed for clean initial state.');

  console.log('🎉 Database seeded successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
