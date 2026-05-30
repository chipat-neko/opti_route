@echo off
REM ============================================================
REM  MAJ_optiroute_chef.bat
REM  Ouvre la derniere version d'opti_route (mode chef) dans
REM  Chrome avec hard-refresh force (vide le cache pour avoir
REM  les dernieres features mergees sur main).
REM
REM  Cible : Noah sur Windows. Place ce fichier sur le bureau et
REM  remplace l'ancien "Installer_optiroute_chef.bat".
REM
REM  La web app est servie depuis GitHub Pages :
REM    https://chipat-neko.github.io/opti_route/
REM
REM  A chaque merge sur main, le deploiement web se relance auto
REM  (workflow deploy-web.yml). Ce script force le navigateur a
REM  recharger en ignorant le cache.
REM ============================================================

setlocal

REM URL de l'app
set URL=https://chipat-neko.github.io/opti_route/

REM Cache-buster : ajoute un timestamp en query pour forcer le
REM chargement frais meme si Chrome a un service worker installe.
for /f %%i in ('powershell -NoProfile -Command "[DateTimeOffset]::Now.ToUnixTimeSeconds()"') do set TS=%%i
set URL_BUST=%URL%?t=%TS%

echo.
echo  ============================================================
echo   opti_route - Mode chef
echo  ============================================================
echo.
echo   Ouverture de la derniere version dans Chrome...
echo   URL : %URL%
echo.
echo   Si tu ne vois pas les nouvelles features :
echo     - Dans Chrome : Ctrl+Shift+R (hard refresh)
echo     - Ou ferme l'onglet et relance ce raccourci
echo.

REM Tente d'ouvrir avec Chrome explicitement (meilleure compat
REM PWA / service worker). Si Chrome pas trouve, fallback sur le
REM navigateur par defaut.
set "CHROME=C:\Program Files\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" set "CHROME=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"

if exist "%CHROME%" (
    start "" "%CHROME%" --new-window "%URL_BUST%"
) else (
    REM Pas de Chrome trouve, on prend ce qui ouvre les liens https
    start "" "%URL_BUST%"
)

REM Auto-close apres 2 sec pour ne pas laisser une fenetre cmd ouverte
timeout /t 2 /nobreak >nul
exit
