# Build APK release + installation sur le telephone connecte en ADB.
#
# Usage : `./scripts/build-and-install.ps1` (depuis la racine du repo)
#
# Pre-requis (auto-detectes, avec fallback sur l'install de Noah) :
# - Flutter : $env:FLUTTER_ROOT, ou `flutter` dans le PATH
# - adb : dans le PATH, ou $env:ANDROID_HOME / $env:ANDROID_SDK_ROOT
# - Un telephone Android connecte en debug USB et autorise

$ErrorActionPreference = 'Stop'

# Flutter : priorite a $env:FLUTTER_ROOT, puis `flutter` dans le PATH,
# sinon fallback sur l'install historique de Noah.
$Flutter = if ($env:FLUTTER_ROOT -and (Test-Path "$env:FLUTTER_ROOT\bin\flutter.bat")) {
  "$env:FLUTTER_ROOT\bin\flutter.bat"
} elseif (Get-Command flutter -ErrorAction SilentlyContinue) {
  (Get-Command flutter).Source
} else {
  'C:\src\flutter\bin\flutter.bat'
}

# adb : priorite au PATH, puis $env:ANDROID_HOME / $env:ANDROID_SDK_ROOT,
# sinon fallback sur l'install historique de Noah.
$Adb = if (Get-Command adb -ErrorAction SilentlyContinue) {
  (Get-Command adb).Source
} elseif ($env:ANDROID_HOME -and (Test-Path "$env:ANDROID_HOME\platform-tools\adb.exe")) {
  "$env:ANDROID_HOME\platform-tools\adb.exe"
} elseif ($env:ANDROID_SDK_ROOT -and (Test-Path "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe")) {
  "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe"
} else {
  'C:\Users\Noah\AppData\Local\Android\sdk\platform-tools\adb.exe'
}

$ApkPath = 'app\build\app\outputs\flutter-apk\app-release.apk'

Push-Location $PSScriptRoot\..\app
try {
  # Les fixtures OCR (assets/test_bordereaux/, ~24 MB) ne servent qu'au
  # batch eval integration_test : on les retire du pubspec le temps du
  # build release, puis on restaure (finally). Sans ca, l'APK Play Store
  # embarque 24 MB d'images de test.
  Copy-Item pubspec.yaml pubspec.yaml.release-bak -Force
  $pubspec = Get-Content pubspec.yaml -Raw
  $stripped = $pubspec -replace '(?m)^\s*-\s*assets/test_bordereaux/\s*\r?\n', ''
  if ($stripped -eq $pubspec) {
    Write-Host '   (note : assets/test_bordereaux/ absent du pubspec, rien a retirer)' -ForegroundColor Yellow
  }
  [System.IO.File]::WriteAllText("$PWD\pubspec.yaml", $stripped)

  Write-Host '[1/3] Build APK release (sans fixtures test_bordereaux)...' -ForegroundColor Cyan
  & $Flutter build apk --release
  if ($LASTEXITCODE -ne 0) { throw 'Build APK echoue' }

  Write-Host '[2/3] Verifie qu un device est connecte...' -ForegroundColor Cyan
  $devices = & $Adb devices | Select-String -Pattern '^\S+\s+device\s*$'
  if (-not $devices) {
    Write-Host '   Aucun device en mode "device" detecte.' -ForegroundColor Yellow
    Write-Host '   Connecte ton telephone en USB + autorise le debug.' -ForegroundColor Yellow
    exit 0
  }

  Write-Host '[3/3] Installation sur le device...' -ForegroundColor Cyan
  Pop-Location
  Push-Location $PSScriptRoot\..
  & $Adb install -r $ApkPath
  if ($LASTEXITCODE -ne 0) { throw 'Install echoue' }

  Write-Host ''
  Write-Host 'OK : opti_route installe. Ouvre l app sur le telephone.' -ForegroundColor Green
}
finally {
  # Restaure le pubspec complet (fixtures test re-declarees pour le dev).
  $bak = Join-Path $PSScriptRoot '..\app\pubspec.yaml.release-bak'
  if (Test-Path $bak) {
    Move-Item $bak (Join-Path $PSScriptRoot '..\app\pubspec.yaml') -Force
  }
  Pop-Location
}
