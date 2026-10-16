@echo off
cd /d %~dp0
where node >nul 2>nul || (echo Install Node.js 20+ from https://nodejs.org first & pause & exit /b 1)
echo Installing build tools (first time only, needs internet)...
call npm install --no-audit --no-fund || (echo npm install failed & pause & exit /b 1)
call npx electron-builder --win nsis --x64 || (echo Build failed & pause & exit /b 1)
echo.
echo Done. Your installer is in the dist-installer folder: ULTRON-Setup-1.1.0.exe
pause
