# POST-RUN CHECKLIST: PII Redaction Patch

## Required Supabase Secrets

### Critical (Must be set)
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for storage writes (NOT anon key)
- `SVN_REDACTION_FEATURE_FLAG=true` - Enable the feature

### Optional (Defaults work)
- `SVN_SERVER_SIDE_PDF=true` - Enable server-side PDF generation (default: true)
- `PRESIDIO_ANALYZER_URL` - Leave blank for regex-only mode
- `PRESIDIO_ANONYMIZER_URL` - Leave blank for regex-only mode

## Function URLs for Testing

Replace `<YOUR_SUPABASE_URL>` with your actual Supabase project URL:

### Health Checks
```bash
# sv_redact health
curl -X GET "<YOUR_SUPABASE_URL>/functions/v1/sv_redact" \
  -H "Authorization: Bearer YOUR_ANON_KEY"

# sv_publish_sample health  
curl -X GET "<YOUR_SUPABASE_URL>/functions/v1/sv_publish_sample" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

Expected response:
```json
{
  "ok": true,
  "version": "1.0.0",
  "flags": {
    "usedPresidio": false,
    "serverSidePdf": true
  }
}
```

## Sample Curl Commands

### Test Redaction (Regex-only)
```bash
curl -X POST "<YOUR_SUPABASE_URL>/functions/v1/sv_redact" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Contact John Smith at john@example.com or 555-123-4567",
    "featureFlag": true,
    "synthetic": false
  }'
```

Expected: `{"redactedText": "Contact [NAME] at [EMAIL] or [PHONE]", "entities": [...], "usedPresidio": false}`

### Test Publish Sample
```bash
IDEMPOTENCY_KEY=$(uuidgen)
curl -X POST "<YOUR_SUPABASE_URL>/functions/v1/sv_publish_sample" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: ${IDEMPOTENCY_KEY}" \
  -d '{
    "recording_id": "test-123",
    "redacted_text": "Contact [NAME] at [EMAIL] or [PHONE]",
    "user_id": "test-user-123",
    "vertical": "health",
    "entities_count_by_type": {"NAME": 1, "EMAIL": 1, "PHONE": 1},
    "used_presidio": false
  }'
```

Expected: `{"publicUrl": "https://...", "manifestUrl": "https://...", "sha256": "..."}`

### Test Idempotency (Same Key)
```bash
# Use the SAME Idempotency-Key from above
curl -X POST "<YOUR_SUPABASE_URL>/functions/v1/sv_publish_sample" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: ${IDEMPOTENCY_KEY}" \
  -d '{
    "recording_id": "test-456",
    "redacted_text": "Different text",
    "user_id": "test-user-456",
    "vertical": "legal",
    "entities_count_by_type": {},
    "used_presidio": false
  }'
```

Expected: Same `publicUrl` as first request, `"idempotencyHit": true`

## One-Click Smoke Test

Run the automated smoke test:
```bash
cd SVN-MVP
./scripts/smoke_export.sh <YOUR_SUPABASE_URL> <YOUR_ANON_KEY>
```

Expected output:
```
=== PII Redaction Export Smoke Test ===

Test 1: Health checks
✓ sv_redact health
✓ sv_publish_sample health

Test 2: Redaction (regex-only)
✓ Redaction working
Entities found: 3

Test 3: Publish sample
✓ Publish successful
Public URL: https://...

Test 4: Idempotency test
✓ Idempotency working

Test 5: Synthetic mode
✓ Synthetic mode working

=== All smoke tests passed! ===
```

## Failure Code Mapping

| Failure Code | User Message |
|--------------|--------------|
| `SERVICE_ROLE_MISSING` | "Server not configured for publishing. Try again after setup." |
| `PATH_RLS_DENIED` | "Couldn't store the sample. We're fixing server permissions." |
| `STORAGE_WRITE_FORBIDDEN` | "Couldn't store the sample. We're fixing server permissions." |
| `PDF_RENDER_ERROR` | "We couldn't create the PDF. Please retry." |
| `REDACTION_413_INPUT_TOO_LARGE` | "Note too long to share. Export a shorter section." |
| `UNKNOWN` | "Couldn't de-identify this sample. Nothing was published." |

## Storage Locations

### PDF Files
```
Bucket: public_redacted_samples
Path:   samples/{userId}/{yyyy}/{MM}/{dd}/{uuid}.pdf
Example: samples/test-user-123/2025/01/19/abc-def-456.pdf
```

### Manifest Files
```
Bucket: public_redacted_samples  
Path:   samples/{userId}/{yyyy}/{MM}/{dd}/{uuid}.json
Example: samples/test-user-123/2025/01/19/abc-def-456.json
```

## Verification Steps

1. ✅ **Health checks pass**: Both functions return `{ok: true}`
2. ✅ **Service role configured**: `SUPABASE_SERVICE_ROLE_KEY` is set
3. ✅ **Feature flag enabled**: `SVN_REDACTION_FEATURE_FLAG=true`
4. ✅ **Server-side PDF**: `SVN_SERVER_SIDE_PDF=true` (default)
5. ✅ **Presidio optional**: Functions work without Presidio URLs
6. ✅ **Idempotency works**: Same key returns same URL
7. ✅ **Path validation**: PDF paths start with `samples/`
8. ✅ **Error codes present**: All errors include `failure_code` field
9. ✅ **Synthetic mode**: Template text works for zero-risk testing
10. ✅ **UI buttons**: Copy-Link and Open buttons in success dialog

## In-App Testing

1. **Settings Toggle**: Enable "Publish de-identified samples" in Settings
2. **Library Export**: Tap share icon on any recording
3. **Synthetic Mode**: Check "Use synthetic text" checkbox
4. **Export**: Tap "Create De-identified PDF (public link)"
5. **Success Dialog**: Should show Copy-Link and Open buttons
6. **Error Handling**: Test with invalid config to see specific error messages

## Common Issues & Solutions

### Issue: "SERVICE_ROLE_MISSING"
**Solution**: Set `SUPABASE_SERVICE_ROLE_KEY` environment variable

### Issue: "STORAGE_WRITE_FORBIDDEN"  
**Solution**: 
1. Verify service role key is correct
2. Check RLS policies on `public_redacted_samples` bucket
3. Ensure path starts with `samples/`

### Issue: "PDF_RENDER_ERROR"
**Solution**: 
1. Check `SVN_SERVER_SIDE_PDF=true` is set
2. Verify server-side PDF generation is working

### Issue: Presidio calls failing
**Solution**: 
- Leave `PRESIDIO_ANALYZER_URL` and `PRESIDIO_ANONYMIZER_URL` empty
- Function will use regex-only mode (graceful degradation)

## Rollback Instructions

If this patch causes issues:

```bash
# 1. Identify the commit hash for this patch
git log --oneline | head -5

# 2. Revert the specific commit
git revert <commit-hash>

# 3. Redeploy edge functions
supabase functions deploy sv_redact
supabase functions deploy sv_publish_sample

# 4. Verify rollback worked
curl -X GET "<YOUR_SUPABASE_URL>/functions/v1/sv_redact" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

---

**Completed**: 2025-01-19
**Files Modified**:
- `assets/config/env.json` (enabled feature flags)
- `supabase/functions/sv_redact/index.ts` (failure codes, Presidio skip)
- `supabase/functions/sv_publish_sample/index.ts` (server-side PDF, failure codes)
- `supabase/functions/_shared/pii_regex.ts` (synthetic templates)
- `lib/services/sample_export_service.dart` (synthetic mode, failure code parsing)
- `lib/presentation/library/library_screen.dart` (Copy-Link + Open buttons)

**New Files**:
- `scripts/smoke_export.sh` (automated smoke test)
- `POST_RUN_CHECKLIST_PATCH.md` (this file)
