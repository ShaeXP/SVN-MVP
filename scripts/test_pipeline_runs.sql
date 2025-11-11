-- Test pipeline_runs table and Realtime functionality
-- Recording ID: 016f2af7-d7bb-45fb-9889-79bd92e4c073

-- ===========================================
-- STEP 1: Check if pipeline_runs table exists
-- ===========================================

SELECT 'Table check' as info,
       CASE 
         WHEN EXISTS (
           SELECT 1 FROM information_schema.tables 
           WHERE table_schema = 'public' AND table_name = 'pipeline_runs'
         ) THEN 'SUCCESS - pipeline_runs table exists'
         ELSE 'FAILED - pipeline_runs table missing'
       END as result;

-- ===========================================
-- STEP 2: Create a test pipeline run
-- ===========================================

-- Insert a test pipeline run for the recording
INSERT INTO public.pipeline_runs (
  recording_id,
  user_id,
  stage,
  progress,
  step,
  message,
  trace_id
) VALUES (
  '016f2af7-d7bb-45fb-9889-79bd92e4c073',
  auth.uid(),
  'queued',
  0.0,
  0,
  'Test pipeline run created',
  'test-trace-' || extract(epoch from now())::text
) RETURNING id as test_run_id;

-- ===========================================
-- STEP 3: Test Realtime with status progression
-- ===========================================

-- Test uploading status
UPDATE public.pipeline_runs
SET stage = 'uploading', progress = 0.15, step = 1, message = 'Starting upload...', updated_at = now()
WHERE recording_id = '016f2af7-d7bb-45fb-9889-79bd92e4c073'
ORDER BY created_at DESC
LIMIT 1;

-- Wait a moment, then test transcribing
-- (Run this after you see the uploading log in Flutter)
UPDATE public.pipeline_runs
SET stage = 'transcribing', progress = 0.45, step = 2, message = 'Transcribing audio...', updated_at = now()
WHERE recording_id = '016f2af7-d7bb-45fb-9889-79bd92e4c073'
ORDER BY created_at DESC
LIMIT 1;

-- Wait a moment, then test summarizing
-- (Run this after you see the transcribing log in Flutter)
UPDATE public.pipeline_runs
SET stage = 'summarizing', progress = 0.75, step = 3, message = 'Generating summary...', updated_at = now()
WHERE recording_id = '016f2af7-d7bb-45fb-9889-79bd92e4c073'
ORDER BY created_at DESC
LIMIT 1;

-- Wait a moment, then test ready
-- (Run this after you see the summarizing log in Flutter)
UPDATE public.pipeline_runs
SET stage = 'ready', progress = 1.0, step = 4, message = 'Pipeline completed successfully!', updated_at = now()
WHERE recording_id = '016f2af7-d7bb-45fb-9889-79bd92e4c073'
ORDER BY created_at DESC
LIMIT 1;

-- Test error status
-- (Run this after you see the ready log in Flutter)
UPDATE public.pipeline_runs
SET stage = 'error', progress = 0.0, step = 99, message = 'Test error state', updated_at = now()
WHERE recording_id = '016f2af7-d7bb-45fb-9889-79bd92e4c073'
ORDER BY created_at DESC
LIMIT 1;

-- Reset to queued for testing
-- (Run this after you see the error log in Flutter)
UPDATE public.pipeline_runs
SET stage = 'queued', progress = 0.0, step = 0, message = 'Reset for testing', updated_at = now()
WHERE recording_id = '016f2af7-d7bb-45fb-9889-79bd92e4c073'
ORDER BY created_at DESC
LIMIT 1;

-- ===========================================
-- EXPECTED FLUTTER LOGS
-- ===========================================

-- After running each UPDATE above, you should see these logs in Flutter console:
/*
[PIPELINE_REALTIME] subscribing to run=<run-id>
[PIPELINE_REALTIME] channel subscribed run_<run-id>
[PIPELINE_REALTIME] received payload for run_<run-id>: {...}
[PIPELINE_REALTIME] parsed stage=uploading, progress=0.15, step=1, message=Starting upload...
[PIPELINE_REALTIME] mapped stage=uploading → status=uploading
[PIPELINE_REALTIME] PipelineRx updated successfully

[PIPELINE_REALTIME] received payload for run_<run-id>: {...}
[PIPELINE_REALTIME] parsed stage=transcribing, progress=0.45, step=2, message=Transcribing audio...
[PIPELINE_REALTIME] mapped stage=transcribing → status=transcribing
[PIPELINE_REALTIME] PipelineRx updated successfully

[PIPELINE_REALTIME] received payload for run_<run-id>: {...}
[PIPELINE_REALTIME] parsed stage=summarizing, progress=0.75, step=3, message=Generating summary...
[PIPELINE_REALTIME] mapped stage=summarizing → status=summarizing
[PIPELINE_REALTIME] PipelineRx updated successfully

[PIPELINE_REALTIME] received payload for run_<run-id>: {...}
[PIPELINE_REALTIME] parsed stage=ready, progress=1.0, step=4, message=Pipeline completed successfully!
[PIPELINE_REALTIME] mapped stage=ready → status=ready
[PIPELINE_REALTIME] PipelineRx updated successfully
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
           WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='pipeline_runs'
         ) THEN 'SUCCESS - Table in Realtime publication'
         ELSE 'FAILED - Table not in Realtime publication'
       END as result;

-- 2. Is RLS policy correct?
SELECT 'RLS policy check' as info,
       CASE 
         WHEN EXISTS (
           SELECT 1 FROM pg_policies
           WHERE schemaname='public' AND tablename='pipeline_runs' AND policyname='select_own_runs'
         ) THEN 'SUCCESS - RLS policy exists'
         ELSE 'FAILED - RLS policy missing'
       END as result;

-- 3. Check the test run
SELECT 'Test run check' as info,
       id,
       recording_id,
       stage,
       progress,
       step,
       message,
       created_at,
       updated_at
FROM public.pipeline_runs 
WHERE recording_id = '016f2af7-d7bb-45fb-9889-79bd92e4c073'
ORDER BY created_at DESC
LIMIT 1;

-- 4. Check if the run is owned by the current user
SELECT 'Run ownership check' as info,
       CASE 
         WHEN user_id = auth.uid() THEN 'SUCCESS - Run owned by current user'
         ELSE 'FAILED - Run not owned by current user'
       END as result,
       user_id,
       auth.uid() as current_user_id
FROM public.pipeline_runs 
WHERE recording_id = '016f2af7-d7bb-45fb-9889-79bd92e4c073'
ORDER BY created_at DESC
LIMIT 1;
