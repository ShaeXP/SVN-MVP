-- Manual test for pipeline_runs with your recording ID
-- Run these one by one and watch Flutter console for [PIPELINE_REALTIME] logs

-- ===========================================
-- STEP 1: Get the run ID for your recording
-- ===========================================

SELECT 
  'Use this run ID for testing:' as instruction,
  id as run_id_to_test
FROM public.pipeline_runs
WHERE recording_id = '016f2af7-d7bb-45fb-9889-79bd92e4c073'
ORDER BY created_at DESC
LIMIT 1;

-- ===========================================
-- STEP 2: Manual status updates (run one by one)
-- ===========================================

-- Test uploading status (15% progress)
-- UPDATE public.pipeline_runs
-- SET stage = 'uploading', progress = 0.15, step = 1, message = 'Starting upload...', updated_at = now()
-- WHERE id = 'YOUR-RUN-ID-FROM-STEP-1';

-- Test transcribing status (45% progress)
-- UPDATE public.pipeline_runs
-- SET stage = 'transcribing', progress = 0.45, step = 2, message = 'Transcribing audio...', updated_at = now()
-- WHERE id = 'YOUR-RUN-ID-FROM-STEP-1';

-- Test summarizing status (75% progress)
-- UPDATE public.pipeline_runs
-- SET stage = 'summarizing', progress = 0.75, step = 3, message = 'Generating summary...', updated_at = now()
-- WHERE id = 'YOUR-RUN-ID-FROM-STEP-1';

-- Test ready status (100% progress)
-- UPDATE public.pipeline_runs
-- SET stage = 'ready', progress = 1.0, step = 4, message = 'Pipeline completed successfully!', updated_at = now()
-- WHERE id = 'YOUR-RUN-ID-FROM-STEP-1';

-- Test error status
-- UPDATE public.pipeline_runs
-- SET stage = 'error', progress = 0.0, step = 99, message = 'Test error state', updated_at = now()
-- WHERE id = 'YOUR-RUN-ID-FROM-STEP-1';

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

-- 3. Check if the run is owned by the current user
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
