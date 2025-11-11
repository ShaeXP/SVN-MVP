$ErrorActionPreference = "Stop"
$PROJECT_REF = "gnskowrijoouemlptrvr"
$BASE = "https://$PROJECT_REF.supabase.co"
$ANON = "sb_publishable_LhchOSgqgJp7lza44fB1eg_ye3V3uGS"
$headers = @{ apikey = $ANON; "Content-Type" = "application/json" }

# unique email per run via timestamp
$ts = [DateTime]::UtcNow.ToString("yyyyMMddHHmmss")
$email = "svntest+$ts@gmail.com"
$password = "Svn!$ts!A1"

Write-Host "Signup => $email"

$signupUrl  = "$BASE/auth/v1/signup"
$signupBody = @{ email=$email; password=$password; data=@{source="sv_smoke"} } | ConvertTo-Json -Compress

try {
  $res = Invoke-RestMethod -Method Post -Uri $signupUrl -Headers $headers -Body $signupBody -ErrorAction Stop
  Write-Host "Signup response:" -ForegroundColor Green
  $res | ConvertTo-Json -Depth 6
} catch {
  $resp = $_.Exception.Response
  if ($resp) {
    $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
    $text = $sr.ReadToEnd(); $code = $resp.StatusCode.value__
    Write-Host "[$code] $text" -ForegroundColor Yellow
  } else { throw }
}

# optional: ask GoTrue to resend the confirmation (covers email delivery path)
$resendUrl  = "$BASE/auth/v1/resend"
$resendBody = @{ type="signup"; email=$email } | ConvertTo-Json -Compress
try {
  $res2 = Invoke-RestMethod -Method Post -Uri $resendUrl -Headers $headers -Body $resendBody -ErrorAction Stop
  Write-Host "Resend response:" -ForegroundColor Green
  $res2 | ConvertTo-Json -Depth 6
} catch {
  $resp = $_.Exception.Response
  if ($resp) {
    $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
    $text = $sr.ReadToEnd(); $code = $resp.StatusCode.value__
    Write-Host "Resend [$code] $text" -ForegroundColor Yellow
  } else { throw }
}

Write-Host "Check Gmail (svntest+TIMESTAMP@gmail.com). Also check Supabase Auth Logs." -ForegroundColor Cyan
