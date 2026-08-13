# Handoff PC — actions qui exigent Flutter/Dart en local.
#
# Contexte : le travail d'audit se fait aussi depuis une machine sans
# Flutter (la CI y fait foi). Trois choses ne peuvent pas y etre faites
# et s'accumulent donc jusqu'au prochain passage sur le PC principal.
# Ce script les enchaine, avec une verification par etape.
#
# Usage (depuis la racine du repo) :
#   pwsh scripts/handoff-pc.ps1              # execute
#   pwsh scripts/handoff-pc.ps1 -WhatIf      # montre sans rien faire
#   pwsh scripts/handoff-pc.ps1 -SkipKeystore
#
# Le script ne commit RIEN : il prepare, verifie, et affiche la
# commande de commit a lancer. Cf docs/handoff-pc-console.md pour les
# actions restantes, qui passent par une console web.

param(
  # Affiche ce qui serait fait, sans rien modifier.
  [switch]$WhatIf,
  # Saute le deplacement de la keystore (etape 3).
  [switch]$SkipKeystore
)

$ErrorActionPreference = 'Stop'
$repo = Resolve-Path "$PSScriptRoot\.."
$app = Join-Path $repo 'app'

function Write-Step([string]$n, [string]$titre) {
  Write-Host ''
  Write-Host "[$n] $titre" -ForegroundColor Cyan
}
function Write-Ok([string]$m) { Write-Host "    OK  $m" -ForegroundColor Green }
function Write-Warn([string]$m) { Write-Host "    /!\ $m" -ForegroundColor Yellow }

# Flutter : meme detection que build-and-install.ps1.
$Flutter = if ($env:FLUTTER_ROOT -and (Test-Path "$env:FLUTTER_ROOT\bin\flutter.bat")) {
  "$env:FLUTTER_ROOT\bin\flutter.bat"
} elseif (Get-Command flutter -ErrorAction SilentlyContinue) {
  (Get-Command flutter).Source
} else {
  'C:\src\flutter\bin\flutter.bat'
}
$Dart = Join-Path (Split-Path $Flutter) 'dart.bat'

if (-not (Test-Path $Flutter)) {
  throw "Flutter introuvable ($Flutter). Definis `$env:FLUTTER_ROOT ou mets flutter dans le PATH."
}
Write-Host "Flutter : $Flutter" -ForegroundColor DarkGray
if ($WhatIf) { Write-Warn 'Mode -WhatIf : aucune commande ne sera executee.' }

# ────────────────────────────────────────────────────────────────
Write-Step '1/3' 'Regeneration du code Drift (database.g.dart)'
# Pourquoi : la purge #532 a retire les tables tracking_codes et sheets
# et fait passer schemaVersion a 52, mais le .g.dart committe date
# d'avant. La CI regenere (build_runner ajoute aux 3 workflows de
# build), pas `flutter run` en local : la machine de dev casse donc au
# demarrage tant que ce n'est pas fait.
$gDart = Join-Path $app 'lib\data\database.g.dart'
$avant = if (Test-Path $gDart) {
  @(Select-String -Path $gDart -Pattern 'TrackingCodes|\$SheetsTable' -AllMatches).Count
} else { 0 }
Write-Host "    Occurrences obsoletes avant : $avant"

if (-not $WhatIf) {
  Push-Location $app
  try {
    & $Dart run build_runner build --delete-conflicting-outputs
    if ($LASTEXITCODE -ne 0) { throw 'build_runner a echoue' }
  } finally { Pop-Location }

  $apres = @(Select-String -Path $gDart -Pattern 'TrackingCodes|\$SheetsTable' -AllMatches).Count
  if ($apres -gt 0) {
    Write-Warn "Il reste $apres occurrence(s) de tracking_codes/sheets dans le .g.dart."
    Write-Warn 'Verifie que database.dart ne les declare plus.'
  } else {
    Write-Ok 'database.g.dart est aligne sur le schema v52.'
  }
}

# ────────────────────────────────────────────────────────────────
Write-Step '2/3' 'pubspec.lock (wakelock_plus)'
# Pourquoi : le lock ne contient pas wakelock_plus, donc les workflows
# ne peuvent pas passer en `--enforce-lockfile` : la CI resout les
# versions librement et peut diverger de la machine de dev.
$lock = Join-Path $app 'pubspec.lock'
$lockAvant = (Select-String -Path $lock -Pattern 'wakelock' -Quiet)
if ($lockAvant) {
  Write-Ok 'wakelock_plus est deja dans le lock, rien a faire.'
} elseif (-not $WhatIf) {
  Push-Location $app
  try {
    & $Flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get a echoue' }
  } finally { Pop-Location }

  if (Select-String -Path $lock -Pattern 'wakelock' -Quiet) {
    Write-Ok 'wakelock_plus est desormais dans pubspec.lock.'
  } else {
    Write-Warn 'wakelock_plus toujours absent du lock : verifie pubspec.yaml.'
  }
}

# ────────────────────────────────────────────────────────────────
Write-Step '3/3' 'Keystore hors de l''arbre du repo'
# Pourquoi : upload-keystore.jks et key.properties n'ont JAMAIS ete
# commites (gitignores deux fois, verifie par
# `git log --all --full-history`), donc la cle n'est pas compromise.
# Mais tant qu'ils vivent dans l'arbre, ils restent a portee d'un
# `git add -f`, d'un zip du dossier ou d'une sauvegarde de disque.
# build.gradle.kts sait deja les lire depuis ~/keystores/opti_route/.
if ($SkipKeystore) {
  Write-Warn 'Etape sautee (-SkipKeystore).'
} else {
  $dest = Join-Path $env:USERPROFILE 'keystores\opti_route'
  $srcJks = Join-Path $app 'android\app\upload-keystore.jks'
  $srcProps = Join-Path $app 'android\key.properties'

  if (-not (Test-Path $srcJks) -and -not (Test-Path $srcProps)) {
    Write-Ok "Rien a deplacer : deja fait, ou cette machine n'a pas la keystore."
  } else {
    Write-Host "    Destination : $dest"
    if (-not $WhatIf) {
      New-Item -ItemType Directory -Force $dest | Out-Null

      # Copie AVANT suppression, et verification du contenu copie : sur
      # certaines machines ce .jks est l'unique exemplaire, le perdre
      # signifie ne plus jamais pouvoir publier de mise a jour sous le
      # meme bundle ID.
      foreach ($src in @($srcJks, $srcProps)) {
        if (-not (Test-Path $src)) { continue }
        $cible = Join-Path $dest (Split-Path $src -Leaf)
        if (Test-Path $cible) {
          Write-Warn "$cible existe deja : source laissee en place, compare-les a la main."
          continue
        }
        Copy-Item $src $cible
        $srcHash = (Get-FileHash $src -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash $cible -Algorithm SHA256).Hash
        if ($srcHash -ne $dstHash) {
          throw "Copie incoherente pour $src : l'original n'est PAS supprime."
        }
        Remove-Item $src
        Write-Ok "$(Split-Path $src -Leaf) deplace (SHA-256 verifie)."
      }
      Write-Warn 'Fais une sauvegarde du .jks sur un support distinct (cf docs/keystore-release.md).'
      Write-Host '    Verifie ensuite un build release : la ligne'
      Write-Host '    "Signing release : key.properties lu depuis ..." doit apparaitre.'
    }
  }
}

# ────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host 'Termine.' -ForegroundColor Green
Write-Host ''
Write-Host 'A committer si les etapes 1 et 2 ont modifie quelque chose :' -ForegroundColor Cyan
Write-Host '    git add app/lib/data/database.g.dart app/pubspec.lock'
Write-Host '    git commit -m "chore: regenere database.g.dart (v52) + pubspec.lock"'
Write-Host ''
Write-Host 'Une fois le .g.dart committe, F15 devient activable :' -ForegroundColor Cyan
Write-Host '    ajouter dans ci.yml, apres le build_runner :'
Write-Host '    git diff --exit-code -- app/lib/**/*.g.dart'
Write-Host ''
Write-Host 'Actions restantes en console web : docs/handoff-pc-console.md' -ForegroundColor Cyan
