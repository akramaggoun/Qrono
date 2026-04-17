const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'qrono_super_secret_jwt_key_2024';
const profUserId = '4ae630c3-bad0-4ca3-8904-f3405f29d57b';
const token = jwt.sign({ id: profUserId, role: 'professor' }, JWT_SECRET, { expiresIn: '24h' });

const baseUrl = 'http://localhost:3000/api';
const headers = {
  'Authorization': `Bearer ${token}`,
  'Content-Type': 'application/json'
};

async function testServer() {
  try {
    console.log('1. Fetching My Sessions...');
    let res = await fetch(`${baseUrl}/sessions/my-sessions`, { headers });
    let data = await res.json();
    const sessions = data.sessions;
    console.log(`Found ${sessions.length} sessions.`);
    
    // Find active session
    const active = sessions.find(s => s.status === 'ACTIVE');
    if (active) {
        console.log('ACTIVE SESSION FOUND:', active.id, 'scheduleId:', active.scheduleId, 'labId:', active.labId);
    } else {
        console.log('NO ACTIVE SESSION FOUND.');
    }

    console.log('\n2. Fetching Schedules...');
    res = await fetch(`${baseUrl}/schedules`, { headers });
    data = await res.json();
    const schedules = data.schedules;
    console.log(`Found ${schedules.length} schedules.`);

    if (schedules.length > 0) {
        const schedule = schedules[0];
        console.log('TESTING CREATE SESSION WITH SCHEDULE:', schedule.id, 'labId:', schedule.labId);

        const now = new Date();
        const end = new Date(now);
        end.setMinutes(end.getMinutes() + 90);

        res = await fetch(`${baseUrl}/sessions`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                courseName: schedule.name,
                startTime: now.toISOString(),
                endTime: end.toISOString(),
                groupId: schedule.groupId,
                labId: schedule.labId,
                scheduleId: schedule.id,
            })
        });
        
        data = await res.json();
        if (res.ok) {
            console.log('CREATE SESSION SUCCESS:', data.session.id);
        } else {
            console.log('CREATE SESSION FAILED (Expected if active exists):', res.status, data.message);
        }
    }
  } catch (err) {
    console.error('API Error:', err);
  }
}

testServer();
