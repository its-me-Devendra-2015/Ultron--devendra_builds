@echo off
rem Builds the custom setup and uninstall UI using electron-builder's bundled NSIS compiler.
cd /d %~dp0..
call npm install --no-audit --no-fund || goto :fail
call npx electron-builder --win dir --x64 || goto :fail
powershell -NoProfile -Command "Compress-Archive -Path 'dist-installer\win-unpacked\*','build\icon.ico','installer\uninstall.ps1' -DestinationPath 'installer\app.zip' -Force" || goto :fail
call npx electron-builder --win nsis --x64 || goto :fail
echo Done. See ULTRON-Setup-*.exe in this folder.
pause & exit /b 0
:fail
echo Build failed.
pause & exit /b 1
