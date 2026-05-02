const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const sessions = await prisma.session.findMany({
    where: {
      courseName: {
        in: ['a', 'b']
      }
    },
    include: {
      professor: {
        include: {
          user: true
        }
      }
    }
  });
  console.log(JSON.stringify(sessions, null, 2));
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
