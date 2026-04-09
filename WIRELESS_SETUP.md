# Wireless QR Scanning Setup Guide

## Overview
This guide explains how to set up wireless QR code scanning for the Qrono attendance system using Cloudflare Tunnel. This allows students to scan QR codes from any device without being on the same local network as the professor's computer.

## Prerequisites
- Cloudflare account
- Domain name (can use Cloudflare's free tier)
- `cloudflared` installed on the professor's computer
- Backend server running

## 🚀 Automated Setup (Recommended)

### One-Command Setup
The easiest way to set up wireless access is using the automated script:

**Windows:**
```cmd
cd devops\tunnel
setup-tunnel.bat
```

**Linux/Mac:**
```bash
cd devops/tunnel
./setup-tunnel.sh
```

**Or using npm:**
```bash
npm run tunnel:setup
```

### What the Automated Script Does:
1. ✅ Checks if `cloudflared` is installed
2. ✅ Handles Cloudflare authentication (opens browser)
3. ✅ Creates the tunnel automatically
4. ✅ Prompts for your domain name
5. ✅ Configures DNS routing
6. ✅ Updates configuration files
7. ✅ Provides final setup instructions

### After Automated Setup:
1. **Start the tunnel:**
   ```bash
   npm run tunnel:start  # or setup-tunnel.bat on Windows
   ```

2. **Configure student apps** with the provided wireless URL

## 📋 Manual Setup (Advanced Users)

### 1. Install cloudflared
```bash
# Download from: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/
# Or via package manager
npm install -g cloudflare/cloudflared
```

### 2. Authenticate with Cloudflare
```bash
cloudflared tunnel login
```
This will open a browser window for authentication.

### 3. Create the tunnel
```bash
cloudflared tunnel create qrono-tunnel
```

### 4. Get tunnel information
```bash
cloudflared tunnel list
```
Note down the tunnel ID (UUID).

### 5. Configure DNS routing
Replace `your-subdomain` and `yourdomain.com` with your actual domain:
```bash
cloudflared tunnel route dns qrono-tunnel qrono-api.your-subdomain.yourdomain.com
```

### 6. Update tunnel configuration
Edit `devops/tunnel/config.yaml`:
```yaml
tunnel: qrono-tunnel
credentials-file: ./credentials.json

ingress:
  - hostname: qrono-api.your-subdomain.yourdomain.com  # Update this
    service: http://localhost:3000
    originRequest:
      noTLSVerify: true
  - service: http_status:404
```

### 7. Start the tunnel
```bash
# On Windows
cd devops/tunnel
start-tunnel.bat

# On Linux/Mac
cd devops/tunnel
./start-tunnel.sh
```

### 8. Configure the mobile app
1. Open the app on the student's phone
2. Go to Settings (gear icon in top right)
3. Select "Wireless (Cloudflare Tunnel)"
4. Enter your tunnel URL: `https://qrono-api.your-subdomain.yourdomain.com/api`
5. Tap "Apply Wireless Settings"
6. Restart the app

## Testing the Setup

### 1. Verify tunnel is running
```bash
# Check status
./status-tunnel.bat  # Windows
./status-tunnel.sh   # Linux/Mac
```

### 2. Test backend accessibility
Open a browser and visit: `https://qrono-api.your-subdomain.yourdomain.com/api/auth/login`

### 3. Test QR scanning
1. Professor creates a session (generates QR code)
2. Student opens app in wireless mode
3. Student scans QR code
4. Attendance should be recorded

## Troubleshooting

### Tunnel not connecting
- Check if `credentials.json` exists
- Verify `config.yaml` has correct domain
- Ensure backend is running on localhost:3000

### App can't connect
- Verify tunnel URL in app settings
- Check if tunnel is running
- Test URL directly in browser

### QR scanning fails
- Ensure student is logged in
- Check session is active
- Verify QR code hasn't expired

## Security Considerations
- Use HTTPS (Cloudflare provides SSL)
- Consider implementing rate limiting
- Monitor tunnel logs for suspicious activity
- Use strong passwords for all accounts

## Architecture
```
Student Phone ──HTTPS──► Cloudflare Tunnel ──HTTP──► Professor's Computer (localhost:3000)
                                      │
                                      └─► PostgreSQL Database
```

## Cost
- Cloudflare Tunnel is **free** for basic usage
- Domain name may have minimal cost (or free with some services)
- No additional server costs required

## Quick Start Summary

**For Professors:**
1. Run: `npm run tunnel:setup`
2. Follow prompts (enter your domain)
3. Run: `npm run tunnel:start`
4. Share the wireless URL with students

**For Students:**
1. Open app → Settings (⚙️) → Wireless mode
2. Enter professor's tunnel URL
3. Scan QR codes wirelessly! 🎉