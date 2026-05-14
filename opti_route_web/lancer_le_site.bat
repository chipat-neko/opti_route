@echo off
REM ============================================================
REM  lancer_le_site.bat
REM  Lance un serveur local (Python http.server) sur le port 8080
REM  et ouvre le navigateur par defaut sur le site.
REM
REM  Flutter Web doit etre servi par un vrai serveur HTTP (pas
REM  ouvert en file://) a cause des restrictions CORS du navigateur
REM  pour le chargement du moteur CanvasKit et des assets.
REM ============================================================

cd /d "%~dp0"

echo.
echo  ============================================================
echo   opti_route web - serveur local
echo  ============================================================
echo.
echo   Serveur demarre sur http://localhost:8080
echo   Ouvre cette URL dans ton navigateur si la fenetre ne s'est
echo   pas ouverte automatiquement.
echo.
echo   Appuie sur Ctrl+C pour arreter le serveur.
echo.

REM Ouvre le navigateur apres 1.5 sec (laisse le temps au serveur)
start "" cmd /c "timeout /t 2 /nobreak >nul && start http://localhost:8080/"

REM Lance le serveur Python (bloque jusqu'a Ctrl+C)
python -m http.server 8080
