@echo off
REM Automated Cloudflare Tunnel Setup for Qrono (Windows)
REM This script handles the complete tunnel setup process

setlocal enabledelayedexpansion

REM Colors for Windows (limited support)
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "BLUE=[94m"
set "NC=[0m"

echo.
echo 🚀 Qrono Wireless QR Scanning - Automated Setup
echo ================================================
echo.

REM Configuration
set "TUNNEL_NAME=qrono-tunnel"
set "CONFIG_FILE=config.yaml"
set "CREDENTIALS_FILE=credentials.json"

goto :main

REM Function to print status messages
:print_status
echo ✅ %~1
exit /b 0

:print_warning
echo ⚠️  %~1
exit /b 0

:print_error
echo ❌ %~1
exit /b 0

:print_info
echo ℹ️  %~1
exit /b 0

:main

REM Step 1: Check prerequisites
echo.
echo 📋 Step 1: Checking Prerequisites
echo ==================================
echo.

REM Check if cloudflared is installed
cloudflared version >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "cloudflared is not installed!"
    echo.
    echo Please install cloudflared first:
    echo 1. Visit: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/
    echo 2. Download and install cloudflared for Windows
    echo 3. Re-run this script
    pause
    exit /b 1
)
call :print_status "cloudflared is installed"

REM Check if config.yaml exists
if not exist "%CONFIG_FILE%" (
    call :print_error "config.yaml not found in current directory"
    echo Please run this script from the devops\tunnel directory
    pause
    exit /b 1
)
call :print_status "Configuration files found"

echo.

REM Step 2: Cloudflare Authentication
echo 📋 Step 2: Cloudflare Authentication
echo =====================================

if not exist "%CREDENTIALS_FILE%" (
    call :print_warning "Cloudflare authentication required"
    echo.
    echo This step requires browser authentication:
    echo 1. A browser window will open
    echo 2. Log in to your Cloudflare account
    echo 3. Grant permission for tunnel access
    echo.
    set /p "dummy=Press Enter to continue and open browser for authentication..."
    echo.
    echo 🔧 Authenticating with Cloudflare...
    cloudflared tunnel login
    if %errorlevel% neq 0 (
        call :print_error "Cloudflare authentication failed"
        pause
        exit /b 1
    )
    call :print_status "Authentication completed"
) else (
    call :print_status "Already authenticated with Cloudflare"
)

echo.

REM Step 3: Create Tunnel
echo 📋 Step 3: Creating Tunnel
echo =========================

REM Check if tunnel already exists
cloudflared tunnel list | findstr "%TUNNEL_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    call :print_status "Tunnel '%TUNNEL_NAME%' already exists"
) else (
    echo 🔧 Creating tunnel '%TUNNEL_NAME%'...
    cloudflared tunnel create %TUNNEL_NAME%
    if %errorlevel% neq 0 (
        call :print_error "Tunnel creation failed"
        pause
        exit /b 1
    )
    call :print_status "Tunnel created successfully"
)

echo.

REM Step 4: Get Tunnel Information
echo 📋 Step 4: Getting Tunnel Information
echo =====================================

for /f "tokens=1" %%i in ('cloudflared tunnel list ^| findstr "%TUNNEL_NAME%"') do set "TUNNEL_ID=%%i"
if "%TUNNEL_ID%"=="" (
    call :print_error "Could not find tunnel ID for '%TUNNEL_NAME%'"
    pause
    exit /b 1
)
call :print_status "Tunnel ID: %TUNNEL_ID%"

echo.

REM Step 5: Domain Configuration
echo 📋 Step 5: Domain Configuration
echo ================================

call :print_info "Domain setup requires manual configuration:"
echo.
echo You need a domain name for wireless access. Options:
echo 1. Use a free subdomain from services like:
echo    - Cloudflare Pages (free)
echo    - ngrok (paid)
echo    - Localtunnel (free)
echo 2. Use your own domain (requires DNS setup)
echo.
echo Example domains:
echo - qrono.yourname.dev (if using a service)
echo - qrono-api.yourdomain.com (your own domain)
echo.

set /p "API_DOMAIN=Enter your domain/subdomain for the API: "

if "%API_DOMAIN%"=="" (
    call :print_error "Domain is required for wireless access"
    pause
    exit /b 1
)

echo.

REM Step 6: DNS Routing Setup
echo 📋 Step 6: DNS Routing Setup
echo =============================

call :print_info "Setting up DNS routing for %API_DOMAIN%"
echo This will point %API_DOMAIN% to your tunnel.
echo.

REM Check if DNS record already exists
cloudflared tunnel route dns list | findstr "%API_DOMAIN%" >nul 2>&1
if %errorlevel% equ 0 (
    call :print_status "DNS routing already configured for %API_DOMAIN%"
) else (
    echo 🔧 Configuring DNS routing...
    cloudflared tunnel route dns %TUNNEL_NAME% %API_DOMAIN%
    if %errorlevel% neq 0 (
        call :print_error "DNS routing configuration failed"
        pause
        exit /b 1
    )
    call :print_status "DNS routing configured"
)

echo.

REM Step 7: Update Configuration
echo 📋 Step 7: Updating Configuration
echo ================================

REM Backup original config
copy "%CONFIG_FILE%" "%CONFIG_FILE%.backup" >nul

REM Update config.yaml with actual values
powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'qrono-api\.yourdomain\.com', '%API_DOMAIN%' | Set-Content '%CONFIG_FILE%'"
call :print_status "Updated config.yaml with domain: %API_DOMAIN%"

echo.

REM Step 8: Test Configuration
echo 📋 Step 8: Testing Configuration
echo ================================

call :print_info "Testing tunnel configuration..."
cloudflared tunnel list | findstr "%TUNNEL_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    call :print_status "Tunnel exists and is configured"
) else (
    call :print_error "Tunnel configuration failed"
    pause
    exit /b 1
)

cloudflared tunnel route dns list | findstr "%API_DOMAIN%" >nul 2>&1
if %errorlevel% equ 0 (
    call :print_status "DNS routing is configured"
) else (
    call :print_error "DNS routing configuration failed"
    pause
    exit /b 1
)

echo.

REM Step 9: Final Instructions
echo.
echo 🎉 Setup Complete!
echo =================
echo.
call :print_status "Cloudflare tunnel configured successfully"
echo.
echo 📱 Wireless Access URL: https://%API_DOMAIN%
echo.
echo 🚀 To start wireless access:
echo   Run: start-tunnel.bat
echo.
echo 📱 Student App Configuration:
echo   1. Open Qrono app on student phone
echo   2. Go to Settings (⚙️ icon)
echo   3. Select 'Wireless (Cloudflare Tunnel)'
echo   4. Enter URL: https://%API_DOMAIN%/api
echo   5. Apply settings and restart app
echo.
echo 🔧 Management Commands:
echo   Status: status-tunnel.bat
echo   Stop:   stop-tunnel.bat
echo.
call :print_info "Setup complete! Students can now scan QR codes wirelessly! 🎉"
echo.
pause