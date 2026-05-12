# Lance scrcpy pour mirrorer l'ecran du telephone Android sur le PC.
#
# Pre-requis :
#   - Telephone branche en USB
#   - Mode developpeur + debogage USB actives
#   - scrcpy installe (winget install Genymobile.scrcpy)
#
# Raccourcis dans la fenetre scrcpy :
#   - Ctrl+Maj+s        : copie une capture dans le presse-papiers
#   - Ctrl+Maj+f        : plein ecran
#   - Ctrl+Maj+r        : enregistre une video
#   - Win+Maj+s         : capture native Windows (cible la fenetre)
#
# Pour faire une capture rapide a m'envoyer :
#   1. Win+Maj+s
#   2. Encadre la fenetre scrcpy
#   3. Colle dans le chat (Ctrl+v)

$scrcpy = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v3.3.4\scrcpy.exe"

if (-not (Test-Path $scrcpy)) {
    # Fallback : chercher dans le PATH (apres redemarrage de session)
    $cmd = Get-Command scrcpy -ErrorAction SilentlyContinue
    if ($cmd) { $scrcpy = $cmd.Source } else { $scrcpy = $null }
}

if (-not $scrcpy -or -not (Test-Path $scrcpy)) {
    Write-Error "scrcpy introuvable. Reinstalle avec : winget install Genymobile.scrcpy"
    exit 1
}

& $scrcpy --window-title="opti_route - Noah" --max-size=1080
