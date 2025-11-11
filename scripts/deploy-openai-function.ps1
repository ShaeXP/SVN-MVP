# Deploy OpenAI summarization function to Supabase
Write-Host "Deploying sv_summarize_openai function..." -ForegroundColor Green

# Check if supabase CLI is available
if (-not (Get-Command "supabase" -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Supabase CLI not found. Please install it first." -ForegroundColor Red
    exit 1
}

# Deploy the function
Write-Host "Deploying function..." -ForegroundColor Yellow
supabase functions deploy sv_summarize_openai

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Function deployed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Set environment variables:" -ForegroundColor White
    Write-Host "   supabase secrets set OPENAI_API_KEY=your_openai_key" -ForegroundColor Gray
    Write-Host "   supabase secrets set SUMMARY_MODEL=gpt-4o-mini" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Test the function with:" -ForegroundColor White
    Write-Host "   supabase functions invoke sv_summarize_openai --data '{\"recordingId\":\"your-recording-id\"}'" -ForegroundColor Gray
} else {
    Write-Host "❌ Function deployment failed!" -ForegroundColor Red
    exit 1
}
