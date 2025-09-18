param(
  [string]$ProjectRoot = ".",
  [string]$PackageName = "lashae_s_application",
  [switch]$Backup
)

$repo = (Resolve-Path $ProjectRoot).Path
$lib  = Join-Path $repo "lib"

# helper: add import if missing (append after last existing import)
function Add-ImportIfMissing {
  param([string]$Text, [string]$ImportLine)
  if ($Text -notmatch [regex]::Escape($ImportLine)) {
    $imports = [regex]::Matches($Text,'(?m)^\s*import\s+.*?;\s*$')
    if ($imports.Count -gt 0) {
      $last = $imports[$imports.Count-1]
      $idx  = $last.Index + $last.Length
      return $Text.Substring(0,$idx) + "`r`n$ImportLine`r`n" + $Text.Substring($idx)
    } else {
      return "$ImportLine`r`n$Text"
    }
  }
  return $Text
}

# optional backup
$backupRoot = $null
if($Backup){
  $backupRoot = Join-Path $repo ("lastfix-backup-{0}" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
  New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
}
function Backup-File { param([string]$FullPath)
  if(-not $Backup){ return }
  $rel = $FullPath.Substring($repo.Length).TrimStart('\','/')
  $dest = Join-Path $backupRoot $rel
  $destDir = Split-Path $dest
  if(-not (Test-Path $destDir)){ New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
  Copy-Item -LiteralPath $FullPath -Destination $dest -Force
}

# ---  A) Fix main.dart  ---
$mainPath = Join-Path $lib "main.dart"
if(Test-Path -LiteralPath $mainPath){
  $main = Get-Content -LiteralPath $mainPath -Raw
  $orig = $main

  # disable missing Supa init (comment out the call)
  $main = [regex]::Replace($main, '^\s*await\s+Supa\.init\(\)\s*;', '// await Supa.init(); // disabled (no Supa class found)',
    [System.Text.RegularExpressions.RegexOptions]::Multiline)

  # darktheme -> darkTheme
  $main = [regex]::Replace($main, '(?i)\bdarktheme\s*:', 'darkTheme:')

  # AppPages.routes -> AppPages.pages
  $main = $main -replace '\bAppPages\.routes\b', 'AppPages.pages'

  # ensure imports
  $impPages = "import 'package:$PackageName/app/routes/app_pages.dart';"
  $impTheme = "import 'package:$PackageName/theme/app_theme_data.dart';"
  if($main -match 'AppPages\.' ){ $main = Add-ImportIfMissing -Text $main -ImportLine $impPages }
  if($main -match 'AppThemeData\.' ){ $main = Add-ImportIfMissing -Text $main -ImportLine $impTheme }

  if($main -ne $orig){
    Backup-File -FullPath $mainPath
    Set-Content -LiteralPath $mainPath -Value $main -Encoding UTF8
    Write-Host "Updated $mainPath"
  } else {
    Write-Host "No changes needed in $mainPath"
  }
} else {
  Write-Host "main.dart not found at $mainPath"
}

# ---  B) Global: AppPages.routes -> AppPages.pages  ---
$dartFiles = Get-ChildItem -Path $lib -Recurse -File -Filter *.dart
foreach($f in $dartFiles){
  $t = Get-Content -LiteralPath $f.FullName -Raw
  if($t -match '\bAppPages\.routes\b'){
    $n = $t -replace '\bAppPages\.routes\b', 'AppPages.pages'
    if($n -ne $t){
      Backup-File -FullPath $f.FullName
      Set-Content -LiteralPath $f.FullName -Value $n -Encoding UTF8
      Write-Host "Rewrote AppPages.routes in $($f.FullName)"
    }
  }
}

# ---  C) Fix CardTheme -> CardThemeData in app_theme_data.dart  ---
$themePath = Join-Path $lib "theme\app_theme_data.dart"
if(Test-Path -LiteralPath $themePath){
  $txt = Get-Content -LiteralPath $themePath -Raw
  if($txt -match 'cardTheme\s*:\s*CardTheme\s*\('){
    $newTxt = [regex]::Replace($txt, 'cardTheme\s*:\s*CardTheme\s*\(', 'cardTheme: CardThemeData(')
    if($newTxt -ne $txt){
      Backup-File -FullPath $themePath
      Set-Content -LiteralPath $themePath -Value $newTxt -Encoding UTF8
      Write-Host "Updated CardTheme -> CardThemeData in $themePath"
    }
  } else {
    Write-Host "No CardTheme replacements needed in $themePath"
  }
} else {
  Write-Host "Theme file not found: $themePath"
}

Write-Host "=== Done ==="
if($Backup){ Write-Host "Backup folder: $backupRoot" }
