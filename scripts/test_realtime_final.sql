-- Test Realtime after migration
-- Run this to verify Realtime is working correctly

-- ===========================================
-- STEP 1: Check migration status
-- ===========================================

-- Verify enum has all 6 canonical values
SELECT 'Enum values' as info, e.enumlabel
FROM pg_type t
JOIN pg_enum e ON e.enumtypid = t.oid
WHERE t.typname = 'recording_status'
ORDER BY e.enumsortorder;

-- Verify only canonical values exist in table
SELECT 'Table status values' as info, 
       DISTINCT status::text AS status_text,
       COUNT(*) as count
FROM public.recordings
GROUP BY status
ORDER BY status;

-- ===========================================
-- STEP 2: Test Realtime with a real recording
-- ===========================================

-- Get the most recent recording for testing
WITH recent_recording AS (
  SELECT id, status, created_at
  FROM public.recordings 
  ORDER BY created_at DESC 
  LIMIT 1
)
SELECT 
  'Test with this recording' as instruction,
  id as recording_id,
  status as current_status,
  created_at
FROM recent_recording;

-- ===========================================
-- STEP 3: Manual Realtime test (uncomment to run)
-- ===========================================

-- Uncomment and run this to test Realtime:
-- Replace 'YOUR-RECORDING-ID' with the ID from step 2

/*
-- Test uploading status
UPDATE public.recordings
SET status='uploading', status_changed_at=now()
WHERE id='YOUR-RECORDING-ID';

-- Wait a moment, then test transcribing
UPDATE public.recordings
SET status='transcribing', status_changed_at=now()
WHERE id='YOUR-RECORDING-ID';

-- Wait a moment, then test summarizing
UPDATE public.recordings
SET status='summarizing', status_changed_at=now()
WHERE id='YOUR-RECORDING-ID';

-- Wait a moment, then test ready
UPDATE public.recordings
SET status='ready', status_changed_at=now()
WHERE id='YOUR-RECORDING-ID';

-- Reset to local for testing
UPDATE public.recordings
SET status='local', status_changed_at=now()
WHERE id='YOUR-RECORDING-ID';
*/

-- ===========================================
-- EXPECTED FLUTTER LOGS
-- ===========================================

-- After running the updates above, you should see these logs in Flutter console:
/*
[REALTIME] subscribing to recording=YOUR-RECORDING-ID
[REALTIME] received payload for rec_YOUR-RECORDING-ID: {...}
[REALTIME] parsed status=uploading, traceId=...
[REALTIME] subscribed rec_YOUR-RECORDING-ID status=uploading
[REALTIME] coordinator updated successfully
[REALTIME] received payload for rec_YOUR-RECORDING-ID: {...}
[REALTIME] parsed status=transcribing, traceId=...
[REALTIME] subscribed rec_YOUR-RECORDING-ID status=transcribing
[REALTIME] coordinator updated successfully
[REALTIME] received payload for rec_YOUR-RECORDING-ID: {...}
[REALTIME] parsed status=summarizing, traceId=...
[REALTIME] subscribed rec_YOUR-RECORDING-ID status=summarizing
[REALTIME] coordinator updated successfully
[REALTIME] received payload for rec_YOUR-RECORDING-ID: {...}
[REALTIME] parsed status=ready, traceId=...
[REALTIME] subscribed rec_YOUR-RECORDING-ID status=ready
[REALTIME] coordinator updated successfully
*/
