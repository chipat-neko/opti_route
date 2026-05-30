@echo off
REM ============================================================
REM  Creer_raccourci_bureau.bat
REM
REM  Cree un raccourci "MAJ opti_route chef.lnk" sur le bureau
REM  qui pointe vers MAJ_optiroute_chef.bat dans ce dossier.
REM
REM  A lancer UNE SEULE FOIS apres avoir clone le repo.
REM  Avantage : tu peux deplacer le repo (E:\ -> D:\...) sans
REM  refaire le raccourci, il pointera toujours vers le bon
REM  dossier scripts/.
REM ============================================================

title Creation raccourci MAJ opti_route

set "TARGET=%~dp0MAJ_optiroute_chef.bat"
set "WORKDIR=%~dp0"
REM Enleve le \ final pour le WorkingDirectory
if "%WORKDIR:~-1%"=="\" set "WORKDIR=%WORKDIR:~0,-1%"
set "SHORTCUT=%USERPROFILE%\Desktop\MAJ opti_route chef.lnk"

if not exist "%TARGET%" (
  echo [ERREUR] MAJ_optiroute_chef.bat introuvable a cote de ce script.
  echo Verifie que tu lances Creer_raccourci_bureau.bat depuis scripts\.
  pause
  exit /b 1
)

echo Creation du raccourci :
echo   Cible    : %TARGET%
echo   Raccourci: %SHORTCUT%
echo.

powershell -NoProfile -Command ^
  "$s = New-Object -ComObject WScript.Shell; ^
   $sc = $s.CreateShortcut('%SHORTCUT%'); ^
   $sc.TargetPath = '%TARGET%'; ^
   $sc.WorkingDirectory = '%WORKDIR%'; ^
   $sc.IconLocation = 'shell32.dll,46'; ^
   $sc.Description = 'Met a jour le logiciel opti_route chef'; ^
   $sc.Save()"

if errorlevel 1 (
  echo [ERREUR] Creation du raccourci a echoue.
  pause
  exit /b 1
)

echo.
echo ============================================================
echo   Raccourci cree sur le bureau.
echo   Double-clic sur "MAJ opti_route chef" pour mettre a jour.
echo ============================================================
pause
exit /b 0
