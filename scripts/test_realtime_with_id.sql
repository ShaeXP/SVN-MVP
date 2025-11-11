-- Test Realtime with specific recording ID
-- Recording ID: 016f2af7-d7bb-45fb-9889-79bd92e4c073

-- ===========================================
-- STEP 1: Check current status of the recording
-- ===========================================

SELECT 
  'Current recording status' as info,
  id,
  status,
  status_changed_at,
  created_at,
  user_id
FROM public.recordings 
WHERE id = '016f2af7-d7bb-45fb-9889-79bd92e4c073';

-- ===========================================
-- STEP 2: Test Realtime with status progression
-- ===========================================

-- Test uploading status
UPDATE public.recordings
SET status = 'uploading', status_changed_at = now()
WHERE id = '016f2af7-d7bb-45fb-9889-79bd92e4c073';

-- Wait a moment, then test transcribing
-- (Run this after you see the uploading log in Flutter)
UPDATE public.recordings
SET status = 'transcribing', status_changed_at = now()
WHERE id = '016f2af7-d7bb-45fb-9889-79bd92e4c073';

-- Wait a moment, then test summarizing
-- (Run this after you see the transcribing log in Flutter)
UPDATE public.recordings
SET status = 'summarizing', status_changed_at = now()
WHERE id = '016f2af7-d7bb-45fb-9889-79bd92e4c073';

-- Wait a moment, then test ready
-- (Run this after you see the summarizing log in Flutter)
UPDATE public.recordings
SET status = 'ready', status_changed_at = now()
WHERE id = '016f2af7-d7bb-45fb-9889-79bd92e4c073';

-- Reset to local for testing
-- (Run this after you see the ready log in Flutter)
UPDATE public.recordings
SET status = 'local', status_changed_at = now()
WHERE id = '016f2af7-d7bb-45fb-9889-79bd92e4c073';

-- ===========================================
-- EXPECTED FLUTTER LOGS
-- ===========================================

-- After running each UPDATE above, you should see these logs in Flutter console:
/*
[REALTIME] subscribing to recording=016f2af7-d7bb-45fb-9889-79bd92e4c073
[REALTIME] received payload for rec_016f2af7-d7bb-45fb-9889-79bd92e4c073: {...}
[REALTIME] parsed status=uploading, traceId=...
[REALTIME] subscribed rec_016f2af7-d7bb-45fb-9889-79bd92e4c073 status=uploading
[REALTIME] coordinator updated successfully

[REALTIME] received payload for rec_016f2af7-d7bb-45fb-9889-79bd92e4c073: {...}
[REALTIME] parsed status=transcribing, traceId=...
[REALTIME] subscribed rec_016f2af7-d7bb-45fb-9889-79bd92e4c073 status=transcribing
[REALTIME] coordinator updated successfully

[REALTIME] received payload for rec_016f2af7-d7bb-45fb-9889-79bd92e4c073: {...}
[REALTIME] parsed status=summarizing, traceId=...
[REALTIME] subscribed rec_016f2af7-d7bb-45fb-9889-79bd92e4c073 status=summarizing
[REALTIME] coordinator updated successfully

[REALTIME] received payload for rec_016f2af7-d7bb-45fb-9889-79bd92e4c073: {...}
[REALTIME] parsed status=ready, traceId=...
[REALTIME] subscribed rec_016f2af7-d7bb-45fb-9889-79bd92e4c073 status=ready
[REALTIME] coordinator updated successfully
*/

-- ===========================================
-- TROUBLESHOOTING
-- ===========================================

-- If you don't see Realtime logs, check these:

-- 1. Is the table in Realtime publication?
SELECT 'Realtime publication check' as info,
       CASE 
         WHEN EXISTS (
           SELECT 1 FROM pg_publication_tables
           WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='recordings'
         ) THEN 'SUCCESS - Table in Realtime publication'
         ELSE 'FAILED - Table not in Realtime publication'
       END as result;

-- 2. Is RLS policy correct?
SELECT 'RLS policy check' as info,
       CASE 
         WHEN EXISTS (
           SELECT 1 FROM pg_policies
           WHERE schemaname='public' AND tablename='recordings' AND policyname='realtime_select_own'
         ) THEN 'SUCCESS - RLS policy exists'
         ELSE 'FAILED - RLS policy missing'
       END as result;

-- 3. Is the recording owned by the current user?
SELECT 'Recording ownership check' as info,
       CASE 
         WHEN user_id = auth.uid() THEN 'SUCCESS - Recording owned by current user'
         ELSE 'FAILED - Recording not owned by current user'
       END as result,
       user_id,
       auth.uid() as current_user_id
FROM public.recordings 
WHERE id = '016f2af7-d7bb-45fb-9889-79bd92e4c073';
