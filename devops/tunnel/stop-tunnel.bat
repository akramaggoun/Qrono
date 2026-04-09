@echo off
REM Stop Cloudflare Tunnel for Qrono (Windows)

echo 🛑 Stopping Qrono Cloudflare Tunnel...

REM Find and kill cloudflared processes
taskkill /f /im cloudflared.exe >nul 2>&1

if %errorlevel% equ 0 (
    echo ✅ Tunnel stopped successfully
) else (
    echo ⚠️  No running tunnel found or failed to stop
)

pause