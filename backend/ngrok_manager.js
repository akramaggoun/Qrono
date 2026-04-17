const ngrok = require('ngrok');
const fs = require('fs');

const PORT = 3000;

async function startTunnel() {
    console.log(`🚀 Starting Professional NGrok Tunnel on port ${PORT}...`);
    
    try {
        const url = await ngrok.connect(PORT);

        console.log(`✅ STABLE LINK: Your Secret Tunnel is active at: ${url}`);
        console.log(`🔗 USE THIS URL IN FLUTTER: ${url}/api`);
        
        // Write URL to a temp file
        fs.writeFileSync('../current_tunnel_url.txt', url);

    } catch (err) {
        console.error('❌ Failed to start NGrok:', err.message);
        setTimeout(startTunnel, 10000);
    }
}

startTunnel();
