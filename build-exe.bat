@echo off
cd /d %~dp0
where node >nul 2>nul || (echo Install Node.js 18+ from https://nodejs.org first & pause & exit /b)
call npm install --no-save @yao-pkg/pkg
call npx pkg app.js --targets node22-win-x64 --output dist/ULTRON.exe
echo.
echo Done: dist\ULTRON.exe
pause
