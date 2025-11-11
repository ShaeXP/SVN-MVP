param(
    [Parameter(Mandatory=$true)][string]$Email,
    [Parameter(Mandatory=$true)][string]$Password
)
$ErrorActionPreference = "Stop"
$PROJECT_REF = "gnskowrijoouemlptrvr"
$BASE = "https://$PROJECT_REF.supabase.co"
$ANON = "sb_publishable_LhchOSgqgJp7lza44fB1eg_ye3V3uGS"
$headers = @{ apikey = $ANON; "Content-Type" = "application/json" }

$url  = "$BASE/auth/v1/token?grant_type=password"
$body = @{ email=$Email; password=$Password } | ConvertTo-Json -Compress

try {
  $res = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body -ErrorAction Stop
  $jwt = $res.access_token
  Write-Host ("JWT: " + $jwt.Substring(0,24) + "…") -ForegroundColor Green
  $res | ConvertTo-Json -Depth 6
} catch {
  $resp = $_.Exception.Response
  if ($resp) {
    $sr = New-Object System.IO.StreamReader($resp.GetResponseStream()); $text = $sr.ReadToEnd()
    $code = $resp.StatusCode.value__
    Write-Host "[$code] $text" -ForegroundColor Yellow
  } else { throw }
}
