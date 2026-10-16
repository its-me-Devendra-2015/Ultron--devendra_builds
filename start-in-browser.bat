@echo off
cd /d %~dp0
where node >nul 2>nul || (echo Install Node.js 18+ from https://nodejs.org first & pause & exit /b)
if not exist .env copy .env.example .env >nul
node app.js --browser
pause
