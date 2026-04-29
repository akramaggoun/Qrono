@echo off
setlocal enabledelayedexpansion
 
:: ==========================================
:: Qrono Full Stack Launcher (Windows)
:: Launch Backend, Frontend, and Cloudflare Tunnel
:: ==========================================
 
set BACKEND_DIR=%~dp0backend
set MOBILE_DIR=%~dp0mobile\flutter_app
set TUNNEL_DIR=%~dp0devops\tunnel
 
:: Backend port for quick tunnel (adjust if needed)
set BACKEND_PORT=3000
 
echo 🚀 Starting Qrono Ecosystem...
echo ------------------------------------------
 
:: 0. Database Maintenance (Optional)
set /p clean_db="Nuke and Seed database before starting? (y/n): "
if /i "%clean_db%"=="y" (
    echo 🧹 Nuking and Seeding Database...
    cd /d "%BACKEND_DIR%"
    node nuke_db.js
    node nuke_history.js
    node prisma/seed.js
    echo ✅ Database reset complete.
)
 
:: 1. Start Tunnel (Background)
echo 📡 [1/3] Starting Cloudflare Quick Tunnel...
cd /d "%TUNNEL_DIR%"
 
:: Kill any leftover cloudflared process so it releases the lock on the old log file
taskkill /f /im cloudflared.exe > nul 2>&1
 
:: Use a fixed absolute path for the log so PowerShell can always find it
set "TUNNEL_LOG=%TUNNEL_DIR%\tunnel_output.log"
 
:: Clean up any previous log (safe now that the process is gone)
if exist "%TUNNEL_LOG%" del /f /q "%TUNNEL_LOG%"
 
:: Launch quick tunnel — no config.yaml needed
start "Qrono Tunnel" /min cmd /c "cloudflared tunnel --url http://localhost:%BACKEND_PORT% > "%TUNNEL_LOG%" 2>&1"
 
echo ⏳ Waiting for tunnel URL (up to 30 seconds)...
set "tunnel_url="
set "counter=0"
 
:wait_loop
if %counter% geq 30 goto :tunnel_timeout
timeout /t 1 /nobreak > nul
 
:: Read the log using a shared FileStream so we can read while cloudflared holds a write lock.
:: Full absolute path is passed so PowerShell finds the file regardless of its working directory.
for /f "delims=" %%U in ('powershell -NoProfile -Command ^
    "try {" ^
    "  $fs = [System.IO.File]::Open(''%TUNNEL_LOG%'', ''Open'', ''Read'', ''ReadWrite'');" ^
    "  $sr = New-Object System.IO.StreamReader($fs);" ^
    "  $log = $sr.ReadToEnd(); $sr.Close(); $fs.Close();" ^
    "  $m = [regex]::Match($log, ''https://[a-zA-Z0-9-]+\.trycloudflare\.com'');" ^
    "  if ($m.Success) { $m.Value }" ^
    "} catch {}" 2^>nul') do set "tunnel_url=%%U"
 
if defined tunnel_url goto :show_url
set /a counter+=1
goto :wait_loop
 
:show_url
echo.
echo ✅ Tunnel is live!
echo 🔗 Quick Tunnel URL: !tunnel_url!
echo    Use this URL in your Flutter app settings for wireless testing.
echo ------------------------------------------
goto :continue_start
 
:tunnel_timeout
echo ⚠️  Tunnel started but URL could not be detected after 20 seconds.
echo    Check the minimized 'Qrono Tunnel' window or tunnel_output.log for the link.
 
:continue_start
 
:: 2. Start Backend (Background)
echo ⚙️  [2/3] Starting Backend Server...
cd /d "%BACKEND_DIR%"
start "Qrono Backend" /min cmd /c "npm run dev"
 
:: 3. Wait for backend to warm up slightly
timeout /t 3 /nobreak > nul
 
:: 4. Start Frontend Options
echo 📱 [3/3] Starting Flutter App...
echo Choose target environment:
echo [1] Browser (Chrome) - Local Testing
echo [2] Android Device - Wireless Debugging
echo [3] All Targets
echo ------------------------------------------
 
set /p target="Selection (1-3): "
 
cd /d "%MOBILE_DIR%"
 
if "%target%"=="1" (
    echo 🌐 Launching Chrome...
    flutter run -d chrome
) else if "%target%"=="2" (
    echo 📲 Launching on Android Device...
    flutter run -d android
) else if "%target%"=="3" (
    echo 🌎 Launching on All Devices...
    flutter run -d all
) else (
    echo ❌ Invalid selection. Exiting.
)
 
pause