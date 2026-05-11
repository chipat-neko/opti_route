param([string]$Path)

# Lecture sans BOM pour eviter decalage de positions
$text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)

$paletteWords = @('cream','creamSoft','paper','ink','inkSoft','inkLine','divider','text','textMute','textFaint')
$pPattern = '\bp\.(' + ($paletteWords -join '|') + ')\b'

$regex = [regex]'\bconst\s+([A-Z]\w*)\s*\('
$allMatches = $regex.Matches($text)

$indicesToStrip = New-Object System.Collections.ArrayList
foreach ($m in $allMatches) {
  $startParen = $m.Index + $m.Length - 1
  $depth = 1
  $i = $startParen + 1
  while ($i -lt $text.Length -and $depth -gt 0) {
    $c = $text[$i]
    if ($c -eq '(') { $depth++ }
    elseif ($c -eq ')') { $depth-- }
    $i++
  }
  if ($depth -ne 0) { continue }
  $inner = $text.Substring($startParen + 1, $i - $startParen - 2)
  if ($inner -match $pPattern) {
    $constMatch = [regex]::Match($m.Value, '^const\s+')
    [void]$indicesToStrip.Add(@{ Index = $m.Index; Length = $constMatch.Length })
  }
}

$sorted = @($indicesToStrip | Sort-Object -Property Index -Descending)
foreach ($t in $sorted) {
  $text = $text.Remove($t.Index, $t.Length)
}

# Ecriture sans BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($Path, $text, $utf8NoBom)
Write-Host ("Stripped " + $sorted.Count + " const blocks: " + $Path)
