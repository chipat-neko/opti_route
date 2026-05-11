param([string]$Path)
$t = Get-Content -Raw $Path
# Ordre : long avant court pour eviter shadow (creamSoft avant cream, textMute/textFaint avant text)
foreach ($name in @('creamSoft','cream','paper','inkSoft','inkLine','divider','textMute','textFaint','text','ink')) {
  $t = $t -replace ('AppColors\.' + $name + '\b'), ('p.' + $name)
}
Set-Content -NoNewline -Encoding UTF8 $Path $t
Write-Host ("Refactored: " + $Path)
