; ULTRON setup bootstrapper. Shows a splash, unpacks the payload to a temp folder and
; starts the custom wizard (installer\wizard.ps1). No stock NSIS pages are shown.
; Build via electron-builder, which supplies NSIS and the output path.
Unicode true
!define VER "1.3.3"
Name "ULTRON Setup"
Icon "${PROJECT_DIR}\build\icon.ico"
RequestExecutionLevel user
SilentInstall silent
SetCompress off
ShowInstDetails nevershow
AutoCloseWindow true
BrandingText " "
!include LogicLib.nsh
Var PS

Section
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"
  File "${PROJECT_DIR}\installer\splash.bmp"
  advsplash::show 1300 350 300 -1 "$PLUGINSDIR\splash"
  Pop $0
  File "${PROJECT_DIR}\installer\wizard.ps1"
  File "${PROJECT_DIR}\installer\app.zip"

  ; prefer 64-bit Windows PowerShell (this exe is 32-bit)
  StrCpy $PS "$WINDIR\sysnative\WindowsPowerShell\v1.0\powershell.exe"
  IfFileExists "$PS" +2 0
  StrCpy $PS "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe"

  nsExec::Exec '"$PS" -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "$PLUGINSDIR\wizard.ps1" -Payload "$PLUGINSDIR\app.zip"'
  Pop $0
  ; 0 = installed, 1 = failed (already shown), 2 = cancelled. Anything else: the wizard window could not start.
  ${If} $0 != 0
  ${AndIf} $0 != 1
  ${AndIf} $0 != 2
    nsExec::Exec '"$PS" -NoProfile -ExecutionPolicy Bypass -File "$PLUGINSDIR\wizard.ps1" -Payload "$PLUGINSDIR\app.zip" -Silent'
    Pop $1
    ${If} $1 == 0
      MessageBox MB_OK|MB_ICONINFORMATION "ULTRON was installed with default settings. Open ULTRON, then Settings, to add your API keys."
    ${Else}
      MessageBox MB_OK|MB_ICONSTOP "Setup could not finish. Details: %TEMP%\ultron-setup.log"
    ${EndIf}
  ${EndIf}
SectionEnd
