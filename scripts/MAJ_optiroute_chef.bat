@echo off
REM ============================================================
REM  MAJ_optiroute_chef.bat
REM
REM  Wrapper qui lance MAJ_optiroute_chef.ps1 (le vrai script).
REM  Le .ps1 a une vraie barre de progression, un mutex anti
REM  double-run et skip si on est deja a jour.
REM
REM  Double-clic = MAJ complete. Cf README.md a cote.
REM ============================================================

title MAJ opti_route chef
set "PS1=%~dp0MAJ_optiroute_chef.ps1"

if not exist "%PS1%" (
  echo [ERREUR] %PS1% introuvable.
  echo Ce .bat doit etre dans le meme dossier que MAJ_optiroute_chef.ps1.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
set "RC=%errorlevel%"

REM Si erreur, pause pour qu'on puisse lire le message avant que la
REM fenetre cmd se ferme. Le .ps1 fait deja un Read-Host en cas
REM d'erreur, mais s'il crash avant d'arriver au Read-Host (erreur
REM de parsing, par exemple), cette pause garantit qu'on voit la
REM raison.
if not "%RC%"=="0" (
  echo.
  echo ============================================================
  echo   Le script a echoue avec le code %RC%.
  echo ============================================================
  pause
)

exit /b %RC%
