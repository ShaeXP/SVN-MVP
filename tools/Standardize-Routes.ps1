# ----- Standardize to Routes + canonical app_pages.dart import (PS 5.1/7+) -----
$root = "lib"
$canonicalPkg     = "package:lashae_s_application/app/routes/app_pages.dart"
$canonicalImport  = "import '$canonicalPkg';"
$backupFolder     = "routefix-backup-{0}" -f (Get-Date -Format "yyyyMMdd_HHmmss")
$projectRoot      = (Get-Location).Path

# Collect .dart files (skip build/.dart_tool)
$files = Get-ChildItem -Path $root -Recurse -File -Include *.dart |
         Where-Object { $_.FullName -notmatch '\\(build|\.dart_tool)\\' }

# Regex patterns that should become the canonical import
$importPatterns = @(
  '(?ms)import\s+["'']\s*package:lashae_s_application/routes/app_pages\.dart["'']\s*;',
  '(?ms)import\s+["'']\s*package:lashae_s_application/routes/app_routes\.dart["'']\s*;',
  '(?ms)import\s+["'']\s*package:lashae_s_application/app/routes/app_routes\.dart["'']\s*;',
  '(?ms)import\s+["''][^"'']*?(?:\\|/)routes(?:\\|/)app_pages\.dart["'']\s*;',
  '(?ms)import\s+["''][^"'']*?(?:\\|/)routes(?:\\|/)app_routes\.dart["'']\s*;',
  '(?ms)import\s+["''][^"'']*?(?:\\|/)app(?:\\|/)routes(?:\\|/)app_routes\.dart["'']\s*;',
  '(?ms)import\s+["''][^"'']*?(?:\\|/)app(?:\\|/)routes(?:\\|/)app_pages\.dart["'']\s*;'
)

$changed = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw
  $new  = $text

  # 1) Detect if this file DEFINES AppRoutes (class/enum). If not, replace AppRoutes. -> Routes.
  $definesAppRoutes = [System.Text.RegularExpressions.Regex]::IsMatch(
    $new,
    '^\s*(?:abstract\s+class|class|enum)\s+AppRoutes\b',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
    [System.Text.RegularExpressions.RegexOptions]::Multiline
  )

  if (-not $definesAppRoutes) {
    $new = [System.Text.RegularExpressions.Regex]::Replace($new, '\bAppRoutes\.', 'Routes.')
  }

  # 2) Normalize any route import to the canonical one
  foreach ($pat in $importPatterns) {
    $new = [System.Text.RegularExpressions.Regex]::Replace($new, $pat, $canonicalImport)
  }

  # 3) If file uses Routes. but lacks canonical import and doesn't import app_export.dart, add canonical import
  $hasCanonical = [System.Text.RegularExpressions.Regex]::IsMatch(
    $new,
    [System.Text.RegularExpressions.Regex]::Escape($canonicalImport)
  )

  $usesRoutes = [System.Text.RegularExpressions.Regex]::IsMatch($new, '\bRoutes\.')
  $hasAppExport = [System.Text.RegularExpressions.Regex]::IsMatch(
    $new,
    'import\s+["''][^"'']*?(?:\\|/)core(?:\\|/)app_export\.dart["'']\s*;'
  )

  if ($usesRoutes -and -not $hasCanonical -and -not $hasAppExport) {
    $nl    = if ($new -match "`r`n") { "`r`n" } else { "`n" }
    $lines = $new -split "\r?\n"

    $lastImport = -1
    for ($i=0; $i -lt $lines.Length; $i++) {
      if ($lines[$i] -match '^\s*import\s+.*;') { $lastImport = $i }
    }

    if ($lastImport -ge 0) {
      $lines = $lines[0..$lastImport] + $canonicalImport + $lines[($lastImport+1)..($lines.Length-1)]
    } else {
      $lines = @($canonicalImport) + $lines
    }

    $new = [string]::Join($nl, $lines)
  }

  if ($new -ne $text) {
    # Backup original into a timestamped folder
    $rel   = $f.FullName.Substring($projectRoot.Length).TrimStart('\','/')
    $dest  = Join-Path $backupFolder $rel
    $dDir  = Split-Path $dest
    if (-not (Test-Path $dDir)) { New-Item -ItemType Directory -Path $dDir -Force | Out-Null }
    Copy-Item -LiteralPath $f.FullName -Destination $dest -Force

    # Write updated file
    Set-Content -LiteralPath $f.FullName -Value $new -Encoding UTF8
    $changed += $f.FullName
  }
}

# Summary
"Changed files: {0}" -f $changed.Count
$changed | ForEach-Object { " - $_" }

# Quick sanity checks
$dartFiles = Get-ChildItem $root -Recurse -File -Include *.dart | Where-Object { $_.FullName -notmatch '\\(build|\.dart_tool)\\' }
$patternPkg = [System.Text.RegularExpressions.Regex]::Escape($canonicalPkg)

"Remaining AppRoutes.* refs: " + (($dartFiles | Select-String -Pattern '\bAppRoutes\.' -ErrorAction SilentlyContinue | Measure-Object).Count)
"Files importing canonical route file: " + ( ($dartFiles | Select-String -Pattern $patternPkg -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path -Unique | Measure-Object).Count )
"Backup folder: $backupFolder"
# -------------------------------------------------------------------------------
