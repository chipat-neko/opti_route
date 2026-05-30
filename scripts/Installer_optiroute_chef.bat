@echo off
title Installation opti_route chef
net session >nul 2>&1
if %errorlevel% neq 0 goto elevate
goto run

:elevate
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:run
set "LOG=%USERPROFILE%\Desktop\optiroute_install_log.txt"
set "REL=E:\opti_route\app\build\windows\x64\runner\Release"
echo opti_route install %date% %time% > "%LOG%"
echo ============================================================
echo   Installation de opti_route (chef PC)
echo ============================================================
echo.
echo [1/2] Approbation du certificat de signature...
certutil -addstore TrustedPeople "%REL%\opti_route.cer" >> "%LOG%" 2>&1
echo     certutil code=%errorlevel% >> "%LOG%"
echo.
echo [2/2] Installation de l'application...
powershell -NoProfile -Command "Add-AppxPackage -Path '%REL%\opti_route.msix'" >> "%LOG%" 2>&1
echo     addappx code=%errorlevel% >> "%LOG%"
echo.
echo ============================================================
echo   Termine. Cherche "opti_route" dans le menu Demarrer.
echo   (Log detaille : %LOG%)
echo ============================================================
echo.
pause
