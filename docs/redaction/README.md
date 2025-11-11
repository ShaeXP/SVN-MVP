# PII Redaction for Public Sample Export

This document describes the PII redaction feature that allows users to export de-identified PDF samples of their recordings for public sharing.

## Overview

The feature provides two levels of PII redaction:
- **V0 (Regex-only)**: Uses compiled regex patterns to identify and redact common PII types
- **V1 (Regex + Presidio)**: Adds Microsoft Presidio for improved entity recognition and redaction

## Architecture

### Components

1. **Edge Functions**:
   - `sv_redact`: Performs PII redaction on text input
   - `sv_publish_sample`: Uploads redacted content as PDF to public storage

2. **Storage**:
   - `public_redacted_samples` bucket with path-scoped read access
   - Path structure: `samples/{userId}/{yyyy}/{MM}/{dd}/{uuid}.pdf`
   - Manifest sidecar: `samples/{userId}/{yyyy}/{MM}/{dd}/{uuid}.json`

3. **Flutter Client**:
   - Settings toggle for feature enablement
   - Export action in Library screen
   - PDF generation using `pdf` package

## Environment Variables

### Required
- `SVN_REDACTION_FEATURE_FLAG`: Global kill-switch (default: `false`)

### Optional (for V1 Presidio integration)
- `PRESIDIO_ANALYZER_URL`: URL to Presidio analyzer service
- `PRESIDIO_ANONYMIZER_URL`: URL to Presidio anonymizer service
- `SVN_SERVER_SIDE_PDF`: Enable server-side PDF generation (default: `false`)

## Regex Patterns (V0)

The system uses anchored, non-backtracking regex patterns to identify:

| Pattern | Regex | Replacement |
|---------|-------|-------------|
| Email | `\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b` | `[EMAIL]` |
| Phone | `(?<!\d)(?:\+?1[-.\s]?)?(?:\(?\d{3}\)?[-.\s]?)\d{3}[-.\s]?\d{4}(?!\d)` | `[PHONE]` |
| URL | `https?:\/\/[^\s]+|www\.[^\s]+` | `[LINK]` |
| IP | `\b(?:\d{1,3}\.){3}\d{1,3}\b` | `[IP]` |
| Date | `\b(?:\d{1,2}[/-]){2}\d{2,4}\b|\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{2,4}\b` | `[DATE]` |
| SSN | `\b\d{3}-\d{2}-\d{4}\b` | `[ID]` |
| Policy/MRN | `(?i)(mrn|chart|medical record|policy|claim|acct|account)\s*[:#]?\s*([A-Z0-9\-]{6,20})` | `[ID]` |
| Names (cue) | `(?i)(Patient|Client|Dr\.|Attorney|Nurse|Judge)\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?` | `[NAME]` |
| Names (capitalized) | `(?<![.!?]\s)\b[A-Z][a-z]+\s+[A-Z][a-z]+\b` | `[NAME]` |
| Organizations | `(?i)(Hospital|Clinic|LLP|LLC|Inc\.|University|Court of|Department of)\s+[A-Z][^\n,]+` | `[ORG]` |

### Safety Features
- Anchored patterns to prevent catastrophic backtracking
- Input size limits (50k characters max)
- Timeout protection (10s max for Edge Functions)
- Adversarial testing with long garbage strings

## API Endpoints

### POST /functions/v1/sv_redact

**Request**:
```json
{
  "text": "string",
  "format": "pdf" | "txt",
  "context": { "vertical": "health" | "legal" | "ops" },
  "featureFlag": boolean,
  "synthetic": false
}
```

**Response**:
```json
{
  "redactedText": "string",
  "entities": [{"type": "string", "start": 0, "end": 0}],
  "entitiesCountByType": {"EMAIL": 1, "PHONE": 2},
  "usedPresidio": boolean,
  "synthetic": boolean
}
```

**Error Codes**:
- `413`: Input too large (>50k chars)
- `400`: Invalid request
- `500`: Redaction failed

### POST /functions/v1/sv_publish_sample

**Request**:
```json
{
  "recording_id": "uuid",
  "redacted_text": "string",
  "user_id": "uuid",
  "vertical": "health" | "legal" | "ops",
  "entities_count_by_type": {},
  "used_presidio": boolean
}
```

**Headers**:
- `Idempotency-Key: <uuid>` (required)

**Response**:
```json
{
  "publicUrl": "string",
  "path": "string",
  "manifestUrl": "string",
  "idempotencyHit": boolean
}
```

## Manifest Format

Each PDF is accompanied by a JSON manifest:

```json
{
  "version": "1.0",
  "createdAt": "2024-01-19T10:30:00Z",
  "entitiesCountByType": {"EMAIL": 2, "PHONE": 1, "NAME": 3},
  "usedPresidio": false,
  "sha256": "abc123...",
  "idempotencyKey": "uuid",
  "vertical": "health",
  "recordingId": "uuid",
  "userId": "uuid"
}
```

## Storage Policies

### Bucket: `public_redacted_samples`

**Read Policy (anon)**:
```sql
bucket_id = 'public_redacted_samples' AND object_name LIKE 'samples/%'
```

**Write Policy**: Service role only (no anon writes)

**Cache Headers**:
- `Cache-Control: public, max-age=31536000, immutable`
- `Content-Disposition: inline; filename="SVN-sample-{vertical}-{date}.pdf"`

## Idempotency

- Each export request requires a unique `Idempotency-Key` header
- Replay protection: same key returns existing file URL
- New key creates new version
- In-memory cache (production should use Redis)

## Fail-Closed Design

- Any error during redaction or upload aborts the entire process
- No public artifacts created on failure
- User sees friendly error message: "Couldn't de-identify this sample. Nothing was published."
- Logs contain entity counts only, never raw PII

## Synthetic Mode

- Zero-risk marketing assets using template text
- Bypasses real transcript data
- Same redaction process applied to template
- Useful for demonstrations and marketing materials

## Logging

**Allowed**:
- Entity counts by type
- Processing durations
- Input lengths
- Success/failure status
- Idempotency hits

**Prohibited**:
- Raw text content
- PII values
- User-identifiable information

## Rollback

**Instant Revert**:
1. Set `SVN_REDACTION_FEATURE_FLAG=false`
2. Client reads flag → export UI hidden
3. No code changes needed

**Full Rollback**:
1. Git revert to commit before this PR
2. Redeploy Edge Functions (removes functions)
3. Keep bucket (harmless; no writes possible)

## Triage & Fix Log (2025-01-19)

### Root Causes Identified

1. **Missing Service Role Validation**: `sv_publish_sample` didn't validate `SUPABASE_SERVICE_ROLE_KEY` exists
2. **No Health Endpoints**: Both functions lacked GET `/health` handlers
3. **No Structured Failure Codes**: Errors returned generic messages
4. **Missing Content-Disposition Header**: PDF uploads lacked proper filename header
5. **Presidio Not Skipped When Missing**: Function attempted Presidio calls even when URLs were empty strings

### Fixes Applied

1. **Phase 1 - Instrumentation**:
   - Added GET `/health` handlers to both functions returning `{ok, version, flags}`
   - Added structured `failure_code` to all error responses
   - Enhanced logging with `redact_ms`, `publish_ms`, `entities_total`, `pdf_size_bytes`

2. **Phase 2 - Service Role & Policies**:
   - Added explicit env validation for `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`
   - Returns `SERVICE_ROLE_MISSING` failure code if missing
   - Added path verification (`samples/{userId}/{yyyy}/{MM}/{dd}/{uuid}.pdf`)
   - Returns `PATH_RLS_DENIED` if path doesn't match RLS policy
   - Added `contentDisposition` header with safe filename

3. **Phase 3 - Presidio & Timeouts**:
   - Skip Presidio if either URL is missing or empty string
   - Implement 7s budget with 3.5s first attempt + 500ms retry
   - Graceful degradation: regex-only on Presidio failure
   - Log `PRESIDIO_UPSTREAM_ERROR` but continue with regex results

4. **Phase 4 - PDF Validation**:
   - Validate PDF content is not empty before upload
   - Return `PDF_RENDER_ERROR` if content is empty
   - Added PDF header watermark

5. **Phase 5 - Enhanced Manifest**:
   - Added `publish_ms` and `redact_ms` to manifest
   - Added `sha256` hash to response
   - Enhanced idempotency logging

6. **Phase 6 - Error Mapping**:
   - Map `REDACTION_413_INPUT_TOO_LARGE` → "That note is too long to share. Try exporting a shorter section."
   - Map `STORAGE_WRITE_FORBIDDEN`/`SERVICE_ROLE_MISSING` → "Server misconfigured. We're on it."
   - Map `PDF_RENDER_ERROR` → "Couldn't create the PDF. Please retry."
   - Default → "Couldn't de-identify this sample. Nothing was published."

### Verification

Run smoke tests:
```bash
cd supabase/functions/_tests
chmod +x smoke_test.sh
./smoke_test.sh <SUPABASE_URL> <ANON_KEY>
```

### Rollback for This Fix

If this fix causes issues:
1. Revert commit: `git revert <commit-hash>`
2. Redeploy functions: `supabase functions deploy sv_redact sv_publish_sample`
3. Previous behavior restored (generic error messages, no health checks)

## Testing

### Unit Tests
- Each regex pattern with positive/negative cases
- Adversarial inputs (long strings, nested patterns)
- Pattern safety validation

### Integration Tests
- End-to-end redaction flow
- Idempotency behavior
- Error handling

### E2E Checklist
- [ ] Toggle OFF → no behavior change
- [ ] Toggle ON → PDF generated, URL returned
- [ ] Synthetic mode → template text, no real data
- [ ] Failure → error toast, no file created
- [ ] Public URL viewable by anyone
- [ ] No direct bucket listing possible
- [ ] Idempotency → same key returns same URL

## Security Considerations

1. **Path-scoped read access**: Prevents bucket enumeration
2. **Service-role only writes**: No anon uploads possible
3. **Input size limits**: Prevents DoS attacks
4. **Timeout protection**: Prevents resource exhaustion
5. **Fail-closed design**: No partial data exposure
6. **Logging restrictions**: No PII in logs

## Performance

- **Input limit**: 50k characters max
- **Timeout**: 10s per Edge Function
- **Presidio timeout**: 1s with single retry
- **Cache**: Immutable cache headers for CDN optimization
- **Idempotency**: Prevents duplicate processing

## Future Enhancements

1. **Server-side PDF**: Optional server-side PDF generation for web clients
2. **Custom patterns**: User-defined regex patterns
3. **Audit trail**: Track who accessed public samples
4. **Expiration**: TTL for public samples
5. **Analytics**: Usage metrics (counts only)
