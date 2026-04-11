@echo off
REM Start Cloudflare Tunnel for Qrono Wireless Access (Windows)
REM This script starts the tunnel to allow wireless QR scanning

echo 🚀 Starting Qrono Cloudflare Tunnel...
echo This will make the backend accessible wirelessly for QR scanning
echo.

REM Check if cloudflared is installed
cloudflared version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ cloudflared is not installed!
    echo Install from: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/
    pause
    exit /b 1
)

REM Check if config.yaml exists
if not exist "config.yaml" (
    echo ❌ config.yaml not found!
    echo Please configure your tunnel first.
    pause
    exit /b 1
)

REM Check if credentials.json exists
if not exist "credentials.json" (
    echo ❌ credentials.json not found!
    echo Run 'cloudflared tunnel login' first.
    pause
    exit /b 1
)

echo ✅ Starting tunnel...
echo Backend will be accessible at: https://qrono-api.yourdomain.com
echo Press Ctrl+C to stop
echo.

REM Start the tunnel
cloudflared tunnel --config config.yaml run qrono-tunnel