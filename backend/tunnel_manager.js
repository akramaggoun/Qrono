const localtunnel = require('localtunnel');
const fs = require('fs');

const PORT = 3000;
const SUBDOMAIN = 'qrono-secure-link'; // Constant subdomain for stable link

async function startTunnel() {
    console.log(`🚀 Starting Persistent Secret Tunnel (subdomain: ${SUBDOMAIN}) on port ${PORT}...`);
    
    try {
        const tunnel = await localtunnel({ 
            port: PORT,
            subdomain: SUBDOMAIN
        });

        console.log(`✅ STABLE LINK ACTIVE: ${tunnel.url}`);
        console.log(`🔗 ANDROID BASE URL: ${tunnel.url}/api`);
        
        fs.writeFileSync('../current_tunnel_url.txt', tunnel.url);

        tunnel.on('close', () => {
            console.log('⚠️ Tunnel closed. Re-starting in 5 seconds...');
            setTimeout(startTunnel, 5000);
        });

    } catch (err) {
        console.error('❌ Tunnel Error:', err.message);
        setTimeout(startTunnel, 5000);
    }
}

startTunnel();
