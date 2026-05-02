@echo off
SETLOCAL EnableDelayedExpansion

set DEVICE_ID=%1
if "%DEVICE_ID%"=="" set DEVICE_ID=chrome

echo Preparing Qrono environment...

:: Assumes the service name is 'postgresql-x64-16' (adjust version number if needed)
echo Checking PostgreSQL...
net start | findstr /i "postgresql" > nul
if %errorlevel% neq 0 (
    echo Starting PostgreSQL service...
    net start postgresql-x64-16
) else (
    echo PostgreSQL is already running.
)

echo Starting Backend...
cd backend

start "Qrono Backend" cmd /c "npm install && npm start"
cd ..

echo Launching Flutter on: %DEVICE_ID%
cd mobile/flutter_app

flutter run -d %DEVICE_ID%

echo.
echo Flutter session ended. 
echo Note: Close the Backend terminal window to fully shut down.
pause
