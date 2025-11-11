# POST-RUN CHECKLIST: PII Redaction Triage & Fix

## Environment Variables Required

### Both Edge Functions
- `SUPABASE_URL` - Your Supabase project URL (e.g., `https://xxx.supabase.co`)
- `SVN_REDACTION_FEATURE_FLAG` - Global kill-switch (set to `true` to enable, default: `false`)

### sv_publish_sample (CRITICAL)
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for storage writes (NOT anon key)

### Optional (Presidio V1)
- `PRESIDIO_ANALYZER_URL` - URL to Presidio analyzer service (e.g., `http://localhost:5001/analyze`)
- `PRESIDIO_ANONYMIZER_URL` - URL to Presidio anonymizer service (e.g., `http://localhost:5002/anonymize`)
- `SVN_SERVER_SIDE_PDF` - Enable server-side PDF generation (default: `false`)

## Edge Function URLs

Replace `<YOUR_SUPABASE_URL>` with your actual Supabase project URL:

### sv_redact
```
GET  <YOUR_SUPABASE_URL>/functions/v1/sv_redact
POST <YOUR_SUPABASE_URL>/functions/v1/sv_redact
```

### sv_publish_sample
```
GET  <YOUR_SUPABASE_URL>/functions/v1/sv_publish_sample
POST <YOUR_SUPABASE_URL>/functions/v1/sv_publish_sample
```

## Quick Health Checks

### Check sv_redact Health
```bash
curl -X GET "https://YOUR_PROJECT.supabase.co/functions/v1/sv_redact" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

Expected response:
```json
{
  "ok": true,
  "version": "1.0.0",
  "flags": {
    "usedPresidio": false,
    "serverSidePdf": false
  }
}
```

### Check sv_publish_sample Health
```bash
curl -X GET "https://YOUR_PROJECT.supabase.co/functions/v1/sv_publish_sample" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

Expected response:
```json
{
  "ok": true,
  "version": "1.0.0",
  "flags": {
    "usedPresidio": false,
    "serverSidePdf": false
  }
}
```

## Idempotency Test

```bash
# Generate a unique idempotency key
IDEMPOTENCY_KEY=$(uuidgen)

# First request - should create new sample
curl -X POST "https://YOUR_PROJECT.supabase.co/functions/v1/sv_publish_sample" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: ${IDEMPOTENCY_KEY}" \
  -d '{
    "recording_id": "test-123",
    "redacted_text": "This is a [NAME] test sample with [EMAIL] redacted.",
    "user_id": "YOUR_USER_ID",
    "vertical": "health",
    "entities_count_by_type": {"NAME": 1, "EMAIL": 1},
    "used_presidio": false
  }'

# Second request with SAME key - should return existing URL
curl -X POST "https://YOUR_PROJECT.supabase.co/functions/v1/sv_publish_sample" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: ${IDEMPOTENCY_KEY}" \
  -d '{
    "recording_id": "test-123",
    "redacted_text": "This is a [NAME] test sample with [EMAIL] redacted.",
    "user_id": "YOUR_USER_ID",
    "vertical": "health",
    "entities_count_by_type": {"NAME": 1, "EMAIL": 1},
    "used_presidio": false
  }'

# Expected: Second response should have "idempotencyHit": true
```

## Storage Locations

### PDF Files
```
Bucket: public_redacted_samples
Path:   samples/{userId}/{yyyy}/{MM}/{dd}/{uuid}.pdf
Example: samples/abc-123/2025/01/19/def-456.pdf
```

### Manifest Files
```
Bucket: public_redacted_samples
Path:   samples/{userId}/{yyyy}/{MM}/{dd}/{uuid}.json
Example: samples/abc-123/2025/01/19/def-456.json
```

## Failure Codes to User Messages

| Failure Code | User Message |
|--------------|--------------|
| `REDACTION_413_INPUT_TOO_LARGE` | "That note is too long to share. Try exporting a shorter section." |
| `SERVICE_ROLE_MISSING` | "Server misconfigured. We're on it." |
| `STORAGE_WRITE_FORBIDDEN` | "Server misconfigured. We're on it." |
| `PDF_RENDER_ERROR` | "Couldn't create the PDF. Please retry." |
| `PATH_RLS_DENIED` | "Server misconfigured. We're on it." |
| `REDACTION_TIMEOUT` | "Couldn't de-identify this sample. Nothing was published." |
| `PRESIDIO_UPSTREAM_ERROR` | (Silent degradation to regex-only, no user error) |
| Default | "Couldn't de-identify this sample. Nothing was published." |

## Verification Steps

1. ✅ **Health checks pass**: Both functions return `{ok: true}`
2. ✅ **Service role configured**: `SUPABASE_SERVICE_ROLE_KEY` is set
3. ✅ **Feature flag default**: `SVN_REDACTION_FEATURE_FLAG` defaults to `false`
4. ✅ **Presidio optional**: Functions work without Presidio URLs
5. ✅ **Idempotency works**: Same key returns same URL
6. ✅ **Path validation**: PDF paths start with `samples/`
7. ✅ **Error codes present**: All errors include `failure_code` field
8. ✅ **Logging safe**: No PII in logs, only entity counts

## Common Issues & Solutions

### Issue: "SERVICE_ROLE_MISSING"
**Solution**: Set `SUPABASE_SERVICE_ROLE_KEY` environment variable for `sv_publish_sample`

### Issue: "STORAGE_WRITE_FORBIDDEN"
**Solution**: 
1. Verify service role key is correct
2. Check RLS policies on `public_redacted_samples` bucket
3. Ensure path starts with `samples/`

### Issue: Presidio calls failing
**Solution**: 
- Check `PRESIDIO_ANALYZER_URL` and `PRESIDIO_ANONYMIZER_URL` are set
- Verify Presidio services are running
- Function will gracefully degrade to regex-only

### Issue: "PATH_RLS_DENIED"
**Solution**: Verify path structure is `samples/{userId}/{yyyy}/{MM}/{dd}/{uuid}.pdf`

## Run Full Smoke Tests

```bash
cd supabase/functions/_tests
chmod +x smoke_test.sh
./smoke_test.sh https://YOUR_PROJECT.supabase.co YOUR_ANON_KEY
```

Expected output: "All smoke tests passed!"

## Rollback Instructions

If this fix causes issues:

```bash
# 1. Identify the commit hash for this fix
git log --oneline | head -5

# 2. Revert the specific commit
git revert <commit-hash>

# 3. Redeploy edge functions
supabase functions deploy sv_redact
supabase functions deploy sv_publish_sample

# 4. Verify rollback worked
curl -X GET "https://YOUR_PROJECT.supabase.co/functions/v1/sv_redact" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

---

**Completed**: 2025-01-19
**Files Modified**:
- `supabase/functions/sv_redact/index.ts`
- `supabase/functions/sv_publish_sample/index.ts`
- `lib/services/sample_export_service.dart`
- `docs/redaction/README.md`

**New Files**:
- `supabase/functions/_tests/smoke_test.sh`
- `POST_RUN_CHECKLIST.md` (this file)
