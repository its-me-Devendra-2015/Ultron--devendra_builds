@echo off
cd /d %~dp0
where node >nul 2>nul || (echo Install Node.js 18+ from https://nodejs.org first & pause & exit /b 1)
if not exist .env copy .env.example .env >nul
if not exist node_modules\electron (
  echo First run: downloading the app window ^(Electron, one time, about 100 MB^)...
  call npm install --no-audit --no-fund || (echo Install failed. Check your internet connection. & pause & exit /b 1)
)
call node_modules\.bin\electron.cmd .
