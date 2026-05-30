# MAJ_optiroute_chef.ps1
#
# Met a jour le logiciel chef opti_route (MSIX) :
#   1. Verifie si on est deja a jour avec origin/main (skip si oui)
#   2. git pull
#   3. flutter pub get
#   4. flutter build windows --release (8-12 min, barre de progression)
#   5. dart run msix:create
#   6. Lance Installer_optiroute_chef.bat (UAC)
#
# Anti double-run : un mutex fichier (lock) empeche 2 instances en
# parallele (cause de la boucle infinie observee 2026-05-30).
#
# Usage : double-clic sur MAJ_optiroute_chef.bat (wrapper).
#         OU : powershell -File MAJ_optiroute_chef.ps1 [-Force] [-NoInstall]
#   -Force : rebuild meme si deja a jour
#   -NoInstall : build seulement, ne lance pas l'installeur
#
# NB : ce script est volontairement ASCII pur (pas d'accents) car
# PowerShell parse les .ps1 UTF-8 sans BOM en CP1252, ce qui casse
# le parsing si y'a des caracteres accentues.

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
        Write-Host "Une autre MAJ est deja en cours (PID $existingPid)." -ForegroundColor Yellow
        Write-Host "Attends qu'elle finisse ou ferme la fenetre cmd correspondante."
        Write-Host ""
        Read-Host "Appuie Entree pour fermer"
        exit 1
    } else {
        # Lock orphelin (la precedente instance a crashe), on nettoie
        Remove-Item $LockFile -Force -ErrorAction SilentlyContinue
    }
}
"$PID" | Out-File $LockFile -Force -Encoding ASCII

# Toujours nettoyer le lock a la sortie (succes, erreur, Ctrl+C)
trap {
    Remove-Item $LockFile -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "ECHEC : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Log detaille : $LogFile"
    Read-Host "Appuie Entree pour fermer"
    exit 1
}

# ---- Sanity checks ----
if (-not (Test-Path (Join-Path $App 'pubspec.yaml'))) {
    throw "Repo introuvable : $App. Edite ce script et change `$Repo en haut."
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

function Invoke-WithProgress {
    # Lance une commande externe via cmd.exe pour avoir un vrai
    # ExitCode (Start-Process directement sur flutter.bat / dart.bat
    # renvoie un ExitCode null car le shim .bat exit avant le binaire
    # final). cmd.exe propage l'exit code du child correctement.
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
    # Construit la cmdline complete : "flutter pub get"
    $cmdLine = $Command + ' ' + ($ArgList -join ' ')
    $proc = Start-Process -FilePath 'cmd.exe' `
        -ArgumentList @('/c', $cmdLine) `
        -PassThru -NoNewWindow `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr
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
            -Status "$Activity - ${mm} min ${ss} s ecoulees" `
            -PercentComplete $pct
    }
    # Append stdout/stderr au log
    Add-Content -Path $LogFile -Value "=== $Activity ==="
    if (Test-Path $stdout) { Add-Content -Path $LogFile -Value (Get-Content $stdout -Raw) }
    if (Test-Path $stderr) { Add-Content -Path $LogFile -Value (Get-Content $stderr -Raw) }
    Remove-Item $stdout, $stderr -Force -ErrorAction SilentlyContinue
    # ExitCode peut etre $null en cas de pepin ; on traite ca comme succes
    # si on a recu des "OK"-like dans le stdout, sinon on throw.
    $ec = $proc.ExitCode
    if ($null -eq $ec) {
        # cmd.exe a au moins demarre, mais ExitCode null = bizarre.
        # On considere comme succes si pas d'erreur capturee.
        Write-Host "  (Exit code indetermine, assume OK)" -ForegroundColor Yellow
    } elseif ($ec -ne 0) {
        throw "$Activity : exit code $ec. Voir $LogFile"
    }
    $elapsed = (Get-Date) - $start
    $mm = [int]$elapsed.TotalMinutes
    $ss = $elapsed.Seconds.ToString('00')
    Write-Host "  OK (${mm} min ${ss} s)" -ForegroundColor Green
}

# ---- Demarrage ----
Show-Header 'Mise a jour opti_route chef (MSIX)'
"opti_route MAJ $(Get-Date)" | Out-File $LogFile -Force
$globalStart = Get-Date

Set-Location $Repo

# ---- 1. Check si a jour ----
# Note : on baisse temporairement ErrorActionPreference pour git car
# git fetch imprime "From https://github.com/..." sur stderr meme en
# cas de succes, ce qui en mode Stop est traite comme une exception.
Write-Progress -Id 1 -Activity 'MAJ opti_route chef (MSIX)' -Status 'Verification version distante' -PercentComplete 5
Write-Host "[1/6] Verification version distante..."
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
git fetch origin main 2>$null
$fetchExit = $LASTEXITCODE
$ErrorActionPreference = $prevEAP
if ($fetchExit -ne 0) { throw "git fetch a echoue (exit $fetchExit)" }
$behindRaw = (git rev-list --count HEAD..origin/main) | Out-String
$behind = $behindRaw.Trim()
if ($behind -eq '0' -and -not $Force) {
    Write-Progress -Id 1 -Activity 'MAJ opti_route chef (MSIX)' -Completed
    Write-Host ""
    Write-Host "Deja a jour avec origin/main. Rien a faire." -ForegroundColor Green
    Write-Host "(Pour forcer un rebuild quand meme : relance avec -Force)"
    Write-Host ""
    Remove-Item $LockFile -ErrorAction SilentlyContinue
    Read-Host "Appuie Entree pour fermer"
    exit 0
}
Write-Host "  $behind commit(s) a pull."

# ---- 2. Pull ----
Write-Host "[2/6] Pull derniere version GitHub..."
Write-Progress -Id 1 -Activity 'MAJ opti_route chef (MSIX)' -Status 'git pull' -PercentComplete 15
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$pullResult = & git pull --ff-only 2>&1 | Out-String
$pullExit = $LASTEXITCODE
$ErrorActionPreference = $prevEAP
Add-Content -Path $LogFile -Value "=== git pull ===`n$pullResult"
if ($pullExit -ne 0) { throw "git pull a echoue (exit $pullExit). Voir $LogFile" }
Write-Host "  OK" -ForegroundColor Green

# ---- 3. pub get ----
Write-Host "[3/6] flutter pub get..."
Invoke-WithProgress -Command 'flutter' -ArgList @('pub', 'get') `
    -Activity 'flutter pub get' -StartPct 20 -EndPct 25 -EstSeconds 30 `
    -WorkDir $App

# ---- 4. Build Windows (8-12 min) ----
Write-Host "[4/6] flutter build windows --release (8 a 12 minutes, sois patient)..."
Invoke-WithProgress -Command 'flutter' -ArgList @(
    'build', 'windows', '--release',
    '--dart-define-from-file=cloud.env.json'
) -Activity 'flutter build windows' -StartPct 30 -EndPct 80 -EstSeconds 600 `
    -WorkDir $App

# ---- 5. MSIX ----
Write-Host "[5/6] dart run msix:create..."
Invoke-WithProgress -Command 'dart' -ArgList @('run', 'msix:create') `
    -Activity 'dart run msix:create' -StartPct 82 -EndPct 92 -EstSeconds 30 `
    -WorkDir $App

# ---- 6. Install (sauf si -NoInstall) ----
# Si le cert MSIX est deja trusted dans LocalMachine\TrustedPeople
# (premiere install passee), on fait `Add-AppxPackage` user-scope
# directement -> pas d'UAC. Sinon fallback sur l'installeur legacy
# qui demande UAC (premiere fois).
if ($NoInstall) {
    Write-Host "[6/6] (-NoInstall) installation skip." -ForegroundColor Yellow
} else {
    Write-Progress -Id 1 -Activity 'MAJ opti_route chef (MSIX)' -Status 'Installation MSIX' -PercentComplete 95
    $ReleaseDir = Join-Path $App 'build\windows\x64\runner\Release'
    $msix = Get-ChildItem $ReleaseDir -Filter '*.msix' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $msix) {
        throw "Aucun .msix trouve dans $ReleaseDir (le build n'a pas produit de package)."
    }

    # Cert deja installe ?
    $certTrusted = $false
    try {
        $certs = Get-ChildItem Cert:\LocalMachine\TrustedPeople -ErrorAction SilentlyContinue |
                 Where-Object { $_.Subject -match 'Msix Testing' }
        if ($certs) { $certTrusted = $true }
    } catch { $certTrusted = $false }

    if ($certTrusted) {
        Write-Host "[6/6] Installation MSIX (cert trusted, pas d'UAC)..."
        $start = Get-Date
        Add-AppxPackage -Path $msix.FullName -ForceApplicationShutdown -ErrorAction Stop
        Start-Sleep -Seconds 2
        $pkg = Get-AppxPackage com.calote.optiroute -ErrorAction SilentlyContinue
        if (-not $pkg) {
            throw "Add-AppxPackage n'a leve aucune erreur mais le package est introuvable."
        }
        $elapsed = (Get-Date) - $start
        Write-Host "  OK (version $($pkg.Version), $([int]$elapsed.TotalSeconds) s)" -ForegroundColor Green
    } else {
        Write-Host "[6/6] Lancement de l'installeur legacy (UAC va demander admin)..."
        if (-not (Test-Path $Installer)) {
            throw "Installer_optiroute_chef.bat introuvable : $Installer. Copie-le depuis $Repo\scripts\."
        }
        Start-Process -FilePath $Installer -Wait
        Write-Host "  OK" -ForegroundColor Green
    }
}

# ---- Fini ----
$totalElapsed = (Get-Date) - $globalStart
$mm = [int]$totalElapsed.TotalMinutes
$ss = $totalElapsed.Seconds.ToString('00')
Write-Progress -Id 1 -Activity 'MAJ opti_route chef (MSIX)' -Completed
Show-Header "Termine en ${mm} min ${ss} s - cherche opti_route dans le menu Demarrer"
Remove-Item $LockFile -ErrorAction SilentlyContinue
Read-Host "Appuie Entree pour fermer"
exit 0
