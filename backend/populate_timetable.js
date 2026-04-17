const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function populate() {
    console.log('⏳ Populating academic timetable with sample lectures...');
    
    try {
        const profs = await prisma.professor.findMany();
        const group = await prisma.group.findFirst();
        const lab = await prisma.laboratory.findFirst();

        if (profs.length === 0 || !group || !lab) {
            console.error('❌ Error: Missing basic data (Professors, Groups, or Labs). Run seed first.');
            return;
        }

        const admin = await prisma.user.findFirst({ where: { role: 'admin' } });

        const scheduleData = [
            { name: 'Algorithmique & Structure de Données', day: 1, start: '08:30', end: '10:00', prof: profs[0] },
            { name: 'Réseaux & Protocoles', day: 1, start: '10:15', end: '11:45', prof: profs[1] },
            { name: 'Systèmes d\'Exploitation', day: 2, start: '13:00', end: '14:30', prof: profs[2] },
            { name: 'Base de Données Avancées', day: 3, start: '08:00', end: '09:30', prof: profs[0] },
            { name: 'Intelligence Artificielle', day: 4, start: '10:00', end: '11:30', prof: profs[1] },
            { name: 'Sécurité Informatique', day: 5, start: '15:00', end: '16:30', prof: profs[2] },
        ];

        for (const data of scheduleData) {
            await prisma.schedule.create({
                data: {
                    name: data.name,
                    description: 'Hesse hebdomadaire obligatoire',
                    professorId: data.prof.id,
                    groupId: group.id,
                    labId: lab.id,
                    dayOfWeek: data.day,
                    startTime: data.start,
                    endTime: data.end,
                    createdByAdminId: admin ? admin.id : null,
                    isActive: true
                }
            });
        }

        console.log('✅ TIMETABLE POPULATED: 6 new lecture slots created.');
        
    } catch (e) {
        console.error('❌ Failed:', e.message);
    } finally {
        await prisma.$disconnect();
    }
}

populate();
