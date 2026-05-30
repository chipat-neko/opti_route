# MAJ_optiroute_chef.ps1
#
# Met à jour le logiciel chef opti_route (MSIX) :
#   1. Vérifie si on est déjà à jour avec origin/main (skip si oui)
#   2. git pull
#   3. flutter pub get
#   4. flutter build windows --release (8-12 min, barre de progression)
#   5. dart run msix:create
#   6. Lance Installer_optiroute_chef.bat (UAC)
#
# Anti double-run : un mutex fichier (lock) empêche 2 instances en
# parallèle (cause de la boucle infinie observée 2026-05-30).
#
# Usage : double-clic sur MAJ_optiroute_chef.bat (wrapper).
#         OU : powershell -File MAJ_optiroute_chef.ps1 [-Force] [-NoInstall]
#   -Force : rebuild même si déjà à jour
#   -NoInstall : build seulement, ne lance pas l'installeur

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$NoInstall
)

$ErrorActionPreference = 'Stop'

# ---- Config ----
$Repo      = 'E:\opti_route'
$App       = Join-Path $Repo 'app'
$Installer = Join-Path $env:USERPROFILE 'Desktop\Installer_optiroute_chef.bat'
$LogFile   = Join-Path $env:USERPROFILE 'Desktop\optiroute_maj_log.txt'
$LockFile  = Join-Path $env:TEMP 'optiroute_maj.lock'

# Nuget sur le PATH (cf feedback_windows_build_exfat)
if (Test-Path 'C:\Users\Noah\nugettools\nuget.exe') {
    $env:Path = "C:\Users\Noah\nugettools;$env:Path"
}

# ---- Mutex anti double-run ----
if (Test-Path $LockFile) {
    $existingPid = Get-Content $LockFile -ErrorAction SilentlyContinue
    $stillAlive = $false
    if ($existingPid) {
        try {
            $proc = Get-Process -Id $existingPid -ErrorAction Stop
            if ($proc) { $stillAlive = $true }
        } catch { $stillAlive = $false }
    }
    if ($stillAlive) {
        Write-Host ""
        Write-Host "Une autre MAJ est déjà en cours (PID $existingPid)." -ForegroundColor Yellow
        Write-Host "Attends qu'elle finisse ou ferme la fenêtre cmd correspondante."
        Write-Host ""
        Read-Host "Appuie Entrée pour fermer"
        exit 1
    } else {
        # Lock orphelin (la précédente instance a crashé), on nettoie
        Remove-Item $LockFile -Force -ErrorAction SilentlyContinue
    }
}
"$PID" | Out-File $LockFile -Force -Encoding ASCII

# Toujours nettoyer le lock à la sortie (succès, erreur, Ctrl+C)
trap {
    Remove-Item $LockFile -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "ÉCHEC : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Log détaillé : $LogFile"
    Read-Host "Appuie Entrée pour fermer"
    exit 1
}

# ---- Sanity checks ----
if (-not (Test-Path (Join-Path $App 'pubspec.yaml'))) {
    throw "Repo introuvable : $App. Édite ce script et change `$Repo en haut."
}
if (-not (Test-Path (Join-Path $App 'cloud.env.json'))) {
    Write-Host "[ATTENTION] $App\cloud.env.json manquant." -ForegroundColor Yellow
    Write-Host "Le build va marcher mais la section 'Sync cloud' sera vide."
    Write-Host ""
}

# ---- Helpers ----
function Show-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host ""
}

function Run-WithProgress {
    param(
        [string]$Command,
        [string[]]$ArgList,
        [string]$Activity,
        [int]$StartPct,
        [int]$EndPct,
        [int]$EstSeconds = 60,
        [string]$WorkDir = $null
    )
    if ($WorkDir) { Set-Location $WorkDir }
    $stdout = Join-Path $env:TEMP "optiroute_maj_stdout_$PID.txt"
    $stderr = Join-Path $env:TEMP "optiroute_maj_stderr_$PID.txt"
    $start  = Get-Date
    $proc = Start-Process -FilePath $Command -ArgumentList $ArgList -PassThru `
        -NoNewWindow -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    while (-not $proc.HasExited) {
        Start-Sleep -Seconds 2
        $elapsed = (Get-Date) - $start
        $secElapsed = [int]$elapsed.TotalSeconds
        $pct = [Math]::Min(
            $EndPct - 1,
            [int]($StartPct + ($EndPct - $StartPct) * ($secElapsed / [double]$EstSeconds))
        )
        $mm = [int]($elapsed.TotalMinutes)
        $ss = $elapsed.Seconds.ToString('00')
        Write-Progress -Id 1 `
            -Activity 'MAJ opti_route chef (MSIX)' `
            -Status "$Activity — $mm min $ss s écoulées" `
            -PercentComplete $pct
    }
    # Append stdout/stderr au log
    Add-Content -Path $LogFile -Value "=== $Activity ==="
    if (Test-Path $stdout) { Add-Content -Path $LogFile -Value (Get-Content $stdout -Raw) }
    if (Test-Path $stderr) { Add-Content -Path $LogFile -Value (Get-Content $stderr -Raw) }
    Remove-Item $stdout, $stderr -Force -ErrorAction SilentlyContinue
    if ($proc.ExitCode -ne 0) {
        throw "$Activity : exit code $($proc.ExitCode). Voir $LogFile"
    }
    $elapsed = (Get-Date) - $start
    $mm = [int]$elapsed.TotalMinutes
    $ss = $elapsed.Seconds.ToString('00')
    Write-Host "  OK ($mm min $ss s)" -ForegroundColor Green
}

# ---- Démarrage ----
Show-Header 'Mise à jour opti_route chef (MSIX)'
"opti_route MAJ $(Get-Date)" | Out-File $LogFile -Force
$globalStart = Get-Date

Set-Location $Repo

# ---- 1. Check si à jour ----
Write-Progress -Id 1 -Activity 'MAJ opti_route chef (MSIX)' -Status 'Vérification version distante' -PercentComplete 5
Write-Host "[1/6] Vérification version distante..."
git fetch origin main 2>&1 | Out-Null
$behindRaw = (git rev-list --count HEAD..origin/main) | Out-String
$behind = $behindRaw.Trim()
if ($behind -eq '0' -and -not $Force) {
    Write-Progress -Id 1 -Activity 'MAJ opti_route chef (MSIX)' -Completed
    Write-Host ""
    Write-Host "Déjà à jour avec origin/main. Rien à faire." -ForegroundColor Green
    Write-Host "(Pour forcer un rebuild quand même : relance avec -Force)"
    Write-Host ""
    Remove-Item $LockFile -ErrorAction SilentlyContinue
    Read-Host "Appuie Entrée pour fermer"
    exit 0
}
Write-Host "  $behind commit(s) à pull."

# ---- 2. Pull ----
Write-Host "[2/6] Pull dernière version GitHub..."
Write-Progress -Id 1 -Activity 'MAJ opti_route chef (MSIX)' -Status 'git pull' -PercentComplete 15
$pullResult = git pull --ff-only 2>&1
Add-Content -Path $LogFile -Value "=== git pull ===`n$pullResult"
if ($LASTEXITCODE -ne 0) { throw "git pull a échoué (exit $LASTEXITCODE)" }
Write-Host "  OK" -ForegroundColor Green

# ---- 3. pub get ----
Write-Host "[3/6] flutter pub get..."
Run-WithProgress -Command 'flutter' -ArgList @('pub', 'get') `
    -Activity 'flutter pub get' -StartPct 20 -EndPct 25 -EstSeconds 30 `
    -WorkDir $App

# ---- 4. Build Windows (8-12 min) ----
Write-Host "[4/6] flutter build windows --release (8-12 min, sois patient)..."
Run-WithProgress -Command 'flutter' -ArgList @(
    'build', 'windows', '--release',
    '--dart-define-from-file=cloud.env.json'
) -Activity 'flutter build windows' -StartPct 30 -EndPct 80 -EstSeconds 600 `
    -WorkDir $App

# ---- 5. MSIX ----
Write-Host "[5/6] dart run msix:create..."
Run-WithProgress -Command 'dart' -ArgList @('run', 'msix:create') `
    -Activity 'dart run msix:create' -StartPct 82 -EndPct 92 -EstSeconds 30 `
    -WorkDir $App

# ---- 6. Install (sauf si -NoInstall) ----
if ($NoInstall) {
    Write-Host "[6/6] (-NoInstall) installation skip." -ForegroundColor Yellow
} else {
    Write-Host "[6/6] Lancement de l'installeur (UAC va demander admin)..."
    Write-Progress -Id 1 -Activity 'MAJ opti_route chef (MSIX)' -Status 'Installation (UAC)' -PercentComplete 95
    if (-not (Test-Path $Installer)) {
        throw "Installer_optiroute_chef.bat introuvable : $Installer. Copie-le depuis $Repo\scripts\."
    }
    Start-Process -FilePath $Installer -Wait
    Write-Host "  OK" -ForegroundColor Green
}

# ---- Fini ----
$totalElapsed = (Get-Date) - $globalStart
$mm = [int]$totalElapsed.TotalMinutes
$ss = $totalElapsed.Seconds.ToString('00')
Write-Progress -Id 1 -Activity 'MAJ opti_route chef (MSIX)' -Completed
Show-Header "Terminé en $mm min $ss s — cherche opti_route dans le menu Démarrer"
Remove-Item $LockFile -ErrorAction SilentlyContinue
Read-Host "Appuie Entrée pour fermer"
exit 0
