-- Manual test script to trigger Realtime events
-- Use this to test if Flutter receives the events

-- 1) Find a recent recording to test with
SELECT 
  'Available recordings for testing' as info,
  id,
  status,
  created_at,
  user_id
FROM public.recordings 
ORDER BY created_at DESC 
LIMIT 5;

-- 2) Get the most recent recording ID for testing
-- Copy the ID from the query above and use it in the updates below
WITH recent_recording AS (
  SELECT id 
  FROM public.recordings 
  ORDER BY created_at DESC 
  LIMIT 1
)
SELECT 
  'Use this ID for testing:' as instruction,
  id as recording_id_to_test
FROM recent_recording;

-- 3) Test status updates (run these one by one and watch Flutter logs)
-- IMPORTANT: Replace the UUID below with the actual ID from step 2

-- Example with a real UUID format (replace with your actual recording ID):
-- UPDATE public.recordings 
-- SET status = 'uploading', status_changed_at = now() 
-- WHERE id = '12345678-1234-1234-1234-123456789abc';

-- Test uploading status
-- UPDATE public.recordings 
-- SET status = 'uploading', status_changed_at = now() 
-- WHERE id = 'REPLACE_WITH_ACTUAL_UUID';

-- Test transcribing status  
-- UPDATE public.recordings 
-- SET status = 'transcribing', status_changed_at = now() 
-- WHERE id = 'REPLACE_WITH_ACTUAL_UUID';

-- Test summarizing status
-- UPDATE public.recordings 
-- SET status = 'summarizing', status_changed_at = now() 
-- WHERE id = 'REPLACE_WITH_ACTUAL_UUID';

-- Test ready status
-- UPDATE public.recordings 
-- SET status = 'ready', status_changed_at = now() 
-- WHERE id = 'REPLACE_WITH_ACTUAL_UUID';

-- Test error status
-- UPDATE public.recordings 
-- SET status = 'error', status_changed_at = now() 
-- WHERE id = 'REPLACE_WITH_ACTUAL_UUID';

-- Reset to local for testing
-- UPDATE public.recordings 
-- SET status = 'local', status_changed_at = now() 
-- WHERE id = 'REPLACE_WITH_ACTUAL_UUID';

-- Expected Flutter logs:
-- [REALTIME] channel subscribed rec_<actual-uuid>
-- [REALTIME] subscribed rec_<actual-uuid> status=uploading
-- [REALTIME] subscribed rec_<actual-uuid> status=transcribing
-- [REALTIME] subscribed rec_<actual-uuid> status=summarizing
-- [REALTIME] subscribed rec_<actual-uuid> status=ready
