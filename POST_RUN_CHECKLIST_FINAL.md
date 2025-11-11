# POST-RUN CHECKLIST: PII Redaction Final Patch

## Function URLs for /health

### sv_redact Health Check
```bash
curl -X GET "https://YOUR_PROJECT.supabase.co/functions/v1/sv_redact" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

Expected response:
```json
{
  "ok": true,
  "usedPresidio": false,
  "serverSidePdf": false
}
```

### sv_publish_sample Health Check
```bash
curl -X GET "https://YOUR_PROJECT.supabase.co/functions/v1/sv_publish_sample" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

Expected response:
```json
{
  "ok": true,
  "usedPresidio": false,
  "serverSidePdf": true
}
```

## Example Curl Lines

### Test Redaction (Regex-only)
```bash
curl -X POST "https://YOUR_PROJECT.supabase.co/functions/v1/sv_redact" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Contact John Smith at john@example.com or 555-123-4567",
    "featureFlag": true,
    "synthetic": false
  }'
```

Expected: `{"redactedText": "Contact [NAME] at [EMAIL] or [PHONE]", "entities": [...], "usedPresidio": false}`

### Test Publish Sample (Synthetic)
```bash
IDEMPOTENCY_KEY=$(uuidgen)
curl -X POST "https://YOUR_PROJECT.supabase.co/functions/v1/sv_publish_sample" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: ${IDEMPOTENCY_KEY}" \
  -d '{
    "recording_id": "test-123",
    "redacted_text": "Sample text",
    "user_id": "test-user-123",
    "vertical": "health",
    "entities_count_by_type": {"NAME": 1, "EMAIL": 1, "PHONE": 1},
    "used_presidio": false,
    "synthetic": true
  }'
```

Expected: `{"publicUrl": "https://...", "manifestUrl": "https://...", "sha256": "..."}`

### Test Idempotency (Same Key)
```bash
# Use the SAME Idempotency-Key from above
curl -X POST "https://YOUR_PROJECT.supabase.co/functions/v1/sv_publish_sample" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: ${IDEMPOTENCY_KEY}" \
  -d '{
    "recording_id": "test-456",
    "redacted_text": "Different text",
    "user_id": "test-user-456",
    "vertical": "legal",
    "entities_count_by_type": {},
    "used_presidio": false,
    "synthetic": true
  }'
```

Expected: Same `publicUrl` as first request, `"idempotencyHit": true`

## Final Object Path for Successful Synthetic Export

### PDF File
```
Bucket: public_redacted_samples
Path:   samples/{userId}/{yyyy}/{MM}/{dd}/{uuid}.pdf
Example: samples/test-user-123/2025/01/19/abc-def-456.pdf
```

### JSON Manifest
```
Bucket: public_redacted_samples
Path:   samples/{userId}/{yyyy}/{MM}/{dd}/{uuid}.json
Example: samples/test-user-123/2025/01/19/abc-def-456.json
```

## Failure Code Mapping

| Failure Code | User Message |
|--------------|--------------|
| `SERVICE_ROLE_MISSING` | "Server not configured to publish yet." |
| `PATH_RLS_DENIED` | "Server storage permissions blocked publishing." |
| `STORAGE_WRITE_FORBIDDEN` | "Server storage permissions blocked publishing." |
| `PDF_RENDER_ERROR` | "Couldn't create the PDF. Please retry." |
| `REDACTION_413_INPUT_TOO_LARGE` | "That note is too long to share. Export a shorter section." |
| `UNKNOWN` | "Couldn't de-identify this sample. Code: UNKNOWN. Nothing was published." |

## Required Environment Variables

### Critical (Must be set)
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for storage writes
- `SVN_REDACTION_FEATURE_FLAG=true` - Enable the feature

### Optional (Defaults work)
- `SVN_SERVER_SIDE_PDF=true` - Enable server-side PDF generation (default: true)
- `PRESIDIO_ANALYZER_URL` - Leave blank for regex-only mode
- `PRESIDIO_ANONYMIZER_URL` - Leave blank for regex-only mode
- `DEBUG_EXPORT_ERRORS=true` - Enable debug echo-error endpoint (optional)

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
11. ✅ **Failure codes**: Machine-readable codes in all error responses
12. ✅ **Request IDs**: Debug logging with request IDs for troubleshooting

## In-App Testing

1. **Settings Toggle**: Enable "Publish de-identified samples" in Settings
2. **Library Export**: Tap share icon on any recording
3. **Synthetic Mode**: Check "Use synthetic text" checkbox
4. **Export**: Tap "Create De-identified PDF (public link)"
5. **Success Dialog**: Should show Copy-Link and Open buttons
6. **Error Handling**: Test with invalid config to see specific error messages with codes

## Debug Endpoint (Optional)

If `DEBUG_EXPORT_ERRORS=true` is set:
```bash
curl -X POST "https://YOUR_PROJECT.supabase.co/functions/v1/sv_publish_sample/echo-error" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

Expected: `{"failure_code": "SERVICE_ROLE_MISSING", "request_id": "..."}`

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
curl -X GET "https://YOUR_PROJECT.supabase.co/functions/v1/sv_redact" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

---

**Completed**: 2025-01-19
**Files Modified**:
- `supabase/functions/sv_redact/index.ts` (failure codes, request IDs, CORS headers)
- `supabase/functions/sv_publish_sample/index.ts` (failure codes, synthetic mode, debug endpoint)
- `lib/services/sample_export_service.dart` (failure code parsing, user-friendly messages)

**Key Features**:
- ✅ Machine-readable failure codes in all error responses
- ✅ Synthetic export path guaranteed to work
- ✅ Request IDs for debugging
- ✅ User-friendly error messages with codes
- ✅ Idempotency enforcement
- ✅ Server-side PDF generation for synthetic mode
