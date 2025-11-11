# Test the OpenAI summarization function
param(
    [string]$RecordingId = "",
    [string]$SupabaseUrl = "http://127.0.0.1:54321",
    [string]$JwtToken = ""
)

Write-Host "Testing sv_summarize_openai function..." -ForegroundColor Green

# Check if RecordingId is provided
if ([string]::IsNullOrEmpty($RecordingId)) {
    Write-Host "Error: Please provide a recording ID" -ForegroundColor Red
    Write-Host "Usage: .\test-openai-function.ps1 -RecordingId 'your-recording-id' [-JwtToken 'your-jwt']" -ForegroundColor Yellow
    exit 1
}

# Check if JWT token is provided
if ([string]::IsNullOrEmpty($JwtToken)) {
    Write-Host "Warning: No JWT token provided. Using local development token." -ForegroundColor Yellow
    $JwtToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
}

# Prepare the request body
$body = @{
    recordingId = $RecordingId
} | ConvertTo-Json

# Prepare headers
$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer $JwtToken"
}

try {
    Write-Host "Sending request to: $SupabaseUrl/functions/v1/sv_summarize_openai" -ForegroundColor Cyan
    Write-Host "Recording ID: $RecordingId" -ForegroundColor Cyan
    
    # Make the request
    $response = Invoke-RestMethod -Uri "$SupabaseUrl/functions/v1/sv_summarize_openai" -Method POST -Body $body -Headers $headers
    
    Write-Host "✅ Function executed successfully!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 3
    
} catch {
    Write-Host "❌ Function execution failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "Status Code: $statusCode" -ForegroundColor Red
        
        # Try to read the error response
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            Write-Host "Error Body: $errorBody" -ForegroundColor Red
        } catch {
            Write-Host "Could not read error response body" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "To test with a real JWT token, use:" -ForegroundColor Cyan
Write-Host ".\test-openai-function.ps1 -RecordingId 'your-id' -JwtToken 'your-real-jwt'" -ForegroundColor Gray
