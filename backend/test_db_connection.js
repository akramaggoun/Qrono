require('dotenv').config();
const prisma = require('./src/utils/prisma.js');

prisma.$connect()
  .then(() => {
    console.log('✅ SUCCESS: Connected to PostgreSQL');
    process.exit(0);
  })
  .catch(err => {
    console.log('❌ FAILED: Could not connect to PostgreSQL');
    console.log('Error:', err.message);
    process.exit(1);
  });
