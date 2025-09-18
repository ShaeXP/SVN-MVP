param(
  [string]$Root = ".",
  [switch]$Backup,
  [switch]$DryRun
)

# Find all .dart files under Root
$files = Get-ChildItem -Path $Root -Recurse -Include *.dart -File

# Regex rules: remove `const` after an arrow returning a Screen/Page,
# and in `page: const FooScreen()` forms.
$rules = @(
  # () => const HomeScreen(...)  -> () => HomeScreen(...)
  @{ Name="Arrow-Const-Screen"; Pattern='=>\s*const\s+([A-Z]\w*(?:Screen|Page)\s*\()'; Replace='=> $1' },

  # page: const HomeScreen(...)  -> page: HomeScreen(...)
  @{ Name="Page-Const-Screen";  Pattern='page\s*:\s*const\s+([A-Z]\w*(?:Screen|Page)\s*\()'; Replace='page: $1' },

  # Generic: () => const <anything>()  -> () => <anything>() (keeps it safe even if not Screen/Page)
  @{ Name="Arrow-Const-Generic"; Pattern='(\(\s*\)\s*=>\s*)const\s+'; Replace='$1' }
)

$changed = 0
foreach ($f in $files) {
  $text = Get-Content -Raw -LiteralPath $f.FullName
  $new  = $text
  $applied = @()

  foreach ($r in $rules) {
    $tmp = [regex]::Replace($new, $r.Pattern, $r.Replace)
    if ($tmp -ne $new) { $applied += $r.Name; $new = $tmp }
  }

  if ($applied.Count -gt 0) {
    if ($DryRun) {
      Write-Host "[DRYRUN] $($f.FullName)  ->  $($applied -join ', ')"
    } else {
      if ($Backup) { Copy-Item -LiteralPath $f.FullName -Destination ($f.FullName + ".bak") -ErrorAction SilentlyContinue }
      Set-Content -LiteralPath $f.FullName -Value $new -Encoding UTF8
      Write-Host "Updated  $($f.FullName)  ->  $($applied -join ', ')"
      $changed++
    }
  }
}

if ($DryRun) {
  Write-Host "`nDry run complete."
} else {
  Write-Host "`nDone. Files changed: $changed"
}
