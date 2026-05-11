param([string]$Path)

$lines = Get-Content $Path
$out = New-Object System.Collections.Generic.List[string]

for ($i = 0; $i -lt $lines.Length; $i++) {
  $line = $lines[$i]
  $out.Add($line)

  # Detecte une ligne qui declare une build(BuildContext context...) ET se termine par "{"
  # (les declarations sur 1 seule ligne couvrent 99% des cas dans ce projet)
  if ($line -match '\bWidget\s+build\s*\(\s*BuildContext\s+context.*\)\s*\{\s*$') {
    # Verifie que la ligne suivante n'a pas deja le snippet
    if ($i + 1 -lt $lines.Length -and $lines[$i + 1] -notmatch 'final\s+p\s*=\s*context\.palette') {
      # Calculer l'indentation : on prend l'indent de la ligne de build + 2 espaces
      $indentMatch = [regex]::Match($line, '^(\s*)')
      $indent = $indentMatch.Groups[1].Value + '  '
      $out.Add($indent + 'final p = context.palette;')
    }
  }
}

Set-Content -Encoding UTF8 $Path $out
Write-Host ("Injected: " + $Path)
