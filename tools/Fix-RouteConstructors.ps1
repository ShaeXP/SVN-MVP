param(
  [string]$ProjectRoot = ".",
  [string]$PackageName = "lashae_s_application",
  [switch]$Backup
)

function Ensure-RoutesImport {
  param([string]$Text,[string]$Pkg)
  $importLine = "import 'package:$Pkg/app/routes/app_routes.dart';"
  if ($Text -notmatch "import\s+['""]package:$Pkg/app/routes/app_routes\.dart['""]\s*;") {
    # insert after the last import; if no import, place at top
    $imports = [regex]::Matches($Text,'(?m)^\s*import\s+.*?;\s*$')
    if ($imports.Count -gt 0) {
      $last = $imports[$imports.Count-1]
      $idx  = $last.Index + $last.Length
      return $Text.Substring(0,$idx) + "`r`n$importLine`r`n" + $Text.Substring($idx)
    } else {
      return "$importLine`r`n$Text"
    }
  }
  return $Text
}

function Has-ConstCtor {
  param([string]$ClassName,[string]$PresentationRoot)
  $pattern = "const\s+$([regex]::Escape($ClassName))\s*\("
  $files = Get-ChildItem -Path $PresentationRoot -Recurse -File -Filter *.dart -ErrorAction SilentlyContinue
  foreach($f in $files){
    $t = Get-Content -LiteralPath $f.FullName -Raw
    if($t -match $pattern){ return $true }
  }
  return $false
}

# Resolve roots
$repo = (Resolve-Path $ProjectRoot).Path
$lib  = Join-Path $repo "lib"
$presentation = Join-Path $lib "presentation"

# Find all app_pages.dart under lib/**/routes/
$appPages = Get-ChildItem -Path $lib -Recurse -File -Filter app_pages.dart | Where-Object {
  $_.FullName -match "\\routes\\"
}

if(-not $appPages){ Write-Host "No app_pages.dart found under $lib"; exit 0 }

# Prepare backup
$backupRoot = $null
if($Backup){
  $backupRoot = Join-Path $repo ("routefix-backup-{0}" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
  New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
}

$summary = @()

foreach($file in $appPages){
  $text = Get-Content -LiteralPath $file.FullName -Raw

  # 1) Ensure the correct import for Routes
  $newText = Ensure-RoutesImport -Text $text -Pkg $PackageName

  # 2) For each GetPage(...) page: () => const Foo(), drop const ONLY if Foo lacks a const ctor
  $constPageMatches = [regex]::Matches($newText, 'page\s*:\s*\(\)\s*=>\s*const\s+([A-Za-z_]\w*)\s*\(')
  $changedHere = $false
  foreach($m in $constPageMatches){
    $cls = $m.Groups[1].Value
    $hasConst = Has-ConstCtor -ClassName $cls -PresentationRoot $presentation
    if(-not $hasConst){
      # replace this specific occurrence
      $pattern = 'page\s*:\s*\(\)\s*=>\s*const\s+' + [regex]::Escape($cls) + '\s*\('
      $replacement = 'page: () => ' + $cls + '('
      $newText = [regex]::Replace($newText, $pattern, $replacement, 1)
      $changedHere = $true
      $summary += "Removed const for $cls in $($file.FullName)"
    }
  }

  # 3) If Routes is still undefined, we can also normalize any lingering AppRoutes. -> Routes.
  if($newText -match '\bAppRoutes\.'){
    $newText = $newText -replace '\bAppRoutes\.', 'Routes.'
    $changedHere = $true
    $summary += "Replaced AppRoutes. -> Routes. in $($file.FullName)"
  }

  if($newText -ne $text){
    if($Backup){
      $rel = $file.FullName.Substring($repo.Length).TrimStart('\','/')
      $dest = Join-Path $backupRoot $rel
      $destDir = Split-Path $dest
      if(-not (Test-Path $destDir)){ New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
      Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
    }
    Set-Content -LiteralPath $file.FullName -Value $newText -Encoding UTF8
  }
}

Write-Host "=== Fix complete ==="
if($Backup){ Write-Host "Backup: $backupRoot" }
$summary | Sort-Object -Unique | ForEach-Object { Write-Host " - $_" }
