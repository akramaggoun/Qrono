@echo off
REM Check Cloudflare Tunnel Status for Qrono (Windows)

echo 📊 Qrono Cloudflare Tunnel Status
echo ==================================

REM Check if cloudflared is running
tasklist /fi "imagename eq cloudflared.exe" /nh | find "cloudflared.exe" >nul
if %errorlevel% equ 0 (
    echo ✅ Tunnel Status: RUNNING
    echo 🌐 Backend accessible at: https://qrono-api.yourdomain.com
    echo 📱 Students can scan QR codes wirelessly
) else (
    echo ❌ Tunnel Status: STOPPED
    echo 💡 Run 'start-tunnel.bat' to start wireless access
)

echo.
echo 📋 Tunnel Configuration:
if exist "config.yaml" (
    echo ✅ config.yaml: Present
) else (
    echo ❌ config.yaml: Missing
)

if exist "credentials.json" (
    echo ✅ credentials.json: Present
) else (
    echo ❌ credentials.json: Missing - Run 'cloudflared tunnel login'
)

echo.
echo 🔧 Quick Setup Commands:
echo 1. cloudflared tunnel login
echo 2. cloudflared tunnel create qrono-tunnel
echo 3. Update config.yaml with your domain
echo 4. cloudflared tunnel route dns qrono-tunnel your-subdomain.yourdomain.com
echo 5. start-tunnel.bat

pause