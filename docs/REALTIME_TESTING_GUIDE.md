# Realtime Pipeline Animation Testing Guide

## Overview
This guide helps you verify that the pipeline animations work correctly with real-time status updates from Supabase.

## Prerequisites
1. Supabase project running
2. Flutter app running in debug mode
3. Console logs visible

## Step 0: Apply Database Migrations

**IMPORTANT**: Before testing Realtime, you must apply the database migrations:

1. **Run the complete migration** in Supabase SQL Editor:
```sql
-- Copy and paste the entire content of this file into Supabase SQL Editor
-- File: scripts/apply_migrations.sql
```

2. **Verify migrations were applied**:
```sql
-- Run this debug script to check everything is working
-- File: scripts/test_realtime_debug.sql
```

**Expected Results:**
- `status_changed_at` column should exist
- `recording_status` enum should exist
- Status column should be of type "USER-DEFINED" (enum)

## Step 1: Verify Database Setup

Run the verification script in Supabase SQL Editor:

```sql
-- Run this in Supabase SQL Editor
\i scripts/test_realtime_setup.sql
```

**Expected Results:**
- All checks should show "PASS"
- Table should be in Realtime publication
- RLS should be enabled with proper policies
- `status_changed_at` column should exist
- `recording_status` enum should exist

## Step 2: Test Manual Status Updates

### Option A: Simple Test (After Migration Applied)
Run this single query in Supabase SQL Editor:
```sql
-- This will test with the most recent recording automatically
UPDATE public.recordings 
SET status = 'transcribing', status_changed_at = now() 
WHERE id = (
  SELECT id 
  FROM public.recordings 
  ORDER BY created_at DESC 
  LIMIT 1
);
```

### Option A2: Basic Test (Before Migration Applied)
If you get "column status_changed_at does not exist", use this instead:
```sql
-- Basic test without status_changed_at column
UPDATE public.recordings 
SET status = 'transcribing' 
WHERE id = (
  SELECT id 
  FROM public.recordings 
  ORDER BY created_at DESC 
  LIMIT 1
);
```

### Option B: Step-by-Step Test
1. **Get a recording ID** from your database:
```sql
SELECT id, status, created_at 
FROM public.recordings 
ORDER BY created_at DESC 
LIMIT 1;
```

2. **Copy the UUID** from the result and use it in this query:
```sql
-- Replace the UUID below with the actual ID from step 1
UPDATE public.recordings 
SET status = 'uploading', status_changed_at = now() 
WHERE id = '12345678-1234-1234-1234-123456789abc';
```

3. **Watch Flutter console** for these logs:
```
[REALTIME] channel subscribed rec_12345678-1234-1234-1234-123456789abc
[REALTIME] subscribed rec_12345678-1234-1234-1234-123456789abc status=uploading
```

### Option C: Automated Test
Run the dynamic test script:
```sql
-- Run this in Supabase SQL Editor
\i scripts/test_realtime_dynamic.sql
```

## Step 3: Test Full Pipeline Flow

1. **Start a recording or upload** in the Flutter app
2. **Watch console logs** for this sequence:
```
[REALTIME] subscribing to recording=abc123
[REALTIME] channel subscribed rec_abc123
[REALTIME] initial status: recording=abc123 status=local
[REALTIME] subscribed rec_abc123 status=uploading
[REALTIME] subscribed rec_abc123 status=transcribing
[REALTIME] subscribed rec_abc123 status=summarizing
[REALTIME] subscribed rec_abc123 status=ready
```

3. **Observe UI animations** - the banner should animate through each stage

## Step 4: Troubleshooting

### No Realtime Logs
**Problem:** No `[REALTIME]` logs appear
**Solutions:**
1. Check if table is in Realtime publication
2. Verify RLS policies allow current user
3. Check network connectivity to Supabase

### Channel Not Subscribing
**Problem:** No "channel subscribed" log
**Solutions:**
1. Check Supabase project URL and keys
2. Verify user is authenticated
3. Check for JavaScript errors in console

### Status Updates Not Received
**Problem:** Manual SQL updates don't trigger Flutter logs
**Solutions:**
1. Verify `REPLICA IDENTITY FULL` is set
2. Check RLS policies
3. Ensure recording belongs to current user

### UI Not Animating
**Problem:** Logs show but UI doesn't update
**Solutions:**
1. Check if `PipelineRx` is created with correct tag
2. Verify `UnifiedPipelineBanner` is using `Obx`
3. Check for layout constraints issues

## Step 5: Edge Function Testing

Test that edge functions write intermediate status updates:

1. **Check edge function logs** in Supabase Dashboard
2. **Look for these log entries:**
```
[sv_run_pipeline] step:status_uploading start
[sv_run_pipeline] step:status_uploading ok
[sv_run_pipeline] step:status_transcribing start
[sv_run_pipeline] step:status_transcribing ok
[sv_run_pipeline] step:status_summarizing start
[sv_run_pipeline] step:status_summarizing ok
[sv_run_pipeline] step:status_ready start
[sv_run_pipeline] step:status_ready ok
```

## Expected Behavior

### Successful Pipeline Flow
1. User starts recording/upload
2. Flutter creates `PipelineRx` and subscribes to Realtime
3. Edge function writes `uploading` status → Flutter receives it
4. Edge function writes `transcribing` status → Flutter receives it
5. Edge function writes `summarizing` status → Flutter receives it
6. Edge function writes `ready` status → Flutter receives it
7. UI animates smoothly through each stage
8. User sees final "Ready" status

### Error Handling
- If Realtime fails, fallback polling takes over
- If edge function fails, status shows "error"
- UI shows retry option for failed recordings

## Performance Expectations

- **Realtime latency:** < 300ms from database write to Flutter update
- **Animation duration:** 250-350ms per stage transition
- **Fallback polling:** Every 3 seconds if Realtime fails
- **Channel cleanup:** Automatic on screen dispose

## Success Criteria

✅ **Database:** Table in Realtime publication with RLS policies
✅ **Edge Functions:** Write intermediate status updates with timestamps
✅ **Flutter:** Receives Realtime events and logs them
✅ **UI:** Animates smoothly through all pipeline stages
✅ **Error Handling:** Graceful fallback and retry mechanisms
