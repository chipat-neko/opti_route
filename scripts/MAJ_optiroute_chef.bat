@echo off
title Mise a jour opti_route (chef PC)
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM  MAJ_optiroute_chef.bat
REM
REM  Met a jour le logiciel chef (MSIX) sur le PC de Noah.
REM  Pull les dernieres sources depuis GitHub + rebuild le MSIX
REM  + lance l'installeur (Installer_optiroute_chef.bat).
REM
REM  Pre-requis : on l'a deja fait pour la premiere install
REM   - E:\opti_route   (clone NTFS)
REM   - VS Build Tools 2022 avec C++ ATL
REM   - C:\Users\Noah\nugettools\nuget.exe sur le PATH
REM   - Dev Mode Windows ON
REM   - app\cloud.env.json present (credentials Supabase)
REM
REM  Place ce .bat sur le bureau. Double-clic = MAJ complete.
REM ============================================================

set "REPO=E:\opti_route"
set "APP=%REPO%\app"
set "INSTALLER=%USERPROFILE%\Desktop\Installer_optiroute_chef.bat"
set "LOG=%USERPROFILE%\Desktop\optiroute_maj_log.txt"

echo opti_route MAJ %date% %time% > "%LOG%"

echo ============================================================
echo   Mise a jour opti_route chef (MSIX)
echo ============================================================
echo.

REM --- Sanity checks ---
if not exist "%APP%\pubspec.yaml" (
  echo [ERREUR] Repo introuvable : %APP%
  echo Verifie que E:\opti_route est bien le clone du projet.
  echo Si tu as bouge le projet, edite ce .bat et change la
  echo variable REPO en haut.
  goto fail
)

if not exist "%APP%\cloud.env.json" (
  echo [ATTENTION] %APP%\cloud.env.json manquant.
  echo Le build va marcher mais la section "Sync cloud" sera vide.
  echo.
)

REM --- 1. Git pull ---
echo [1/5] Pull derniere version GitHub...
cd /d "%REPO%"
git pull --ff-only >> "%LOG%" 2>&1
if errorlevel 1 (
  echo     git pull a echoue. Voir %LOG%
  goto fail
)
echo     OK
echo.

REM --- 2. flutter pub get ---
echo [2/5] flutter pub get...
cd /d "%APP%"
call flutter pub get >> "%LOG%" 2>&1
if errorlevel 1 (
  echo     flutter pub get a echoue. Voir %LOG%
  goto fail
)
echo     OK
echo.

REM --- 3. flutter build windows ---
echo [3/5] flutter build windows --release...
echo     (cela peut prendre 8-12 min, sois patient)
set "PATH=C:\Users\Noah\nugettools;%PATH%"
call flutter build windows --release --dart-define-from-file=cloud.env.json >> "%LOG%" 2>&1
if errorlevel 1 (
  echo     Le build a echoue. Voir %LOG%
  goto fail
)
echo     OK
echo.

REM --- 4. dart run msix:create ---
echo [4/5] Packaging MSIX...
call dart run msix:create >> "%LOG%" 2>&1
if errorlevel 1 (
  echo     msix:create a echoue. Voir %LOG%
  goto fail
)
echo     OK
echo.

REM --- 5. Lancer l'installeur ---
echo [5/5] Lancement de l'installeur (UAC va demander admin)...
if not exist "%INSTALLER%" (
  echo     ATTENTION : Installer_optiroute_chef.bat introuvable sur le
  echo     bureau. Tu peux le retrouver dans le repo :
  echo     %REPO%\scripts\Installer_optiroute_chef.bat
  echo     Copie-le sur le bureau et relance ce script.
  goto fail
)

echo.
echo ============================================================
echo   Build OK. Lancement de Installer_optiroute_chef.bat...
echo   (Approuve UAC quand Windows demande)
echo ============================================================
echo.
call "%INSTALLER%"

goto end

:fail
echo.
echo ============================================================
echo   ECHEC. Consulte le log : %LOG%
echo ============================================================
pause
exit /b 1

:end
echo.
echo ============================================================
echo   Mise a jour terminee. Lance opti_route depuis le menu
echo   Demarrer (cherche "opti_route").
echo   Log : %LOG%
echo ============================================================
pause
exit /b 0
