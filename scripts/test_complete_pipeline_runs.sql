-- Complete test for pipeline_runs with your recording ID
-- This script tests the full end-to-end pipeline_runs functionality

-- ===========================================
-- STEP 1: Create pipeline_runs table (if not exists)
-- ===========================================

CREATE TABLE IF NOT EXISTS public.pipeline_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recording_id uuid NOT NULL REFERENCES public.recordings(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  stage text NOT NULL CHECK (stage IN ('queued','uploading','transcribing','summarizing','ready','error')),
  progress real CHECK (progress >= 0 AND progress <= 1),
  step int NOT NULL DEFAULT 0,
  message text,
  trace_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.pipeline_runs;
ALTER TABLE public.pipeline_runs REPLICA IDENTITY FULL;

-- Enable RLS
ALTER TABLE public.pipeline_runs ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='pipeline_runs' AND policyname='select_own_runs'
  ) THEN
    CREATE POLICY select_own_runs ON public.pipeline_runs
      FOR SELECT USING (auth.uid() = user_id);
  END IF;
END $$;

-- ===========================================
-- STEP 2: Create a test pipeline run
-- ===========================================

-- Insert a test pipeline run for your recording
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
-- STEP 3: Test Realtime with realistic progress
-- ===========================================

-- Test uploading status (15% progress)
UPDATE public.pipeline_runs
SET stage = 'uploading', progress = 0.15, step = 1, message = 'Starting upload...', updated_at = now()
WHERE recording_id = '016f2af7-d7bb-45fb-9889-79bd92e4c073'
ORDER BY created_at DESC
LIMIT 1;

-- Wait 2-3 seconds, then test transcribing (45% progress)
-- (Run this after you see the uploading log in Flutter)
UPDATE public.pipeline_runs
SET stage = 'transcribing', progress = 0.45, step = 2, message = 'Transcribing audio...', updated_at = now()
WHERE recording_id = '016f2af7-d7bb-45fb-9889-79bd92e4c073'
ORDER BY created_at DESC
LIMIT 1;

-- Wait 2-3 seconds, then test summarizing (75% progress)
-- (Run this after you see the transcribing log in Flutter)
UPDATE public.pipeline_runs
SET stage = 'summarizing', progress = 0.75, step = 3, message = 'Generating summary...', updated_at = now()
WHERE recording_id = '016f2af7-d7bb-45fb-9889-79bd92e4c073'
ORDER BY created_at DESC
LIMIT 1;

-- Wait 2-3 seconds, then test ready (100% progress)
-- (Run this after you see the summarizing log in Flutter)
UPDATE public.pipeline_runs
SET stage = 'ready', progress = 1.0, step = 4, message = 'Pipeline completed successfully!', updated_at = now()
WHERE recording_id = '016f2af7-d7bb-45fb-9889-79bd92e4c073'
ORDER BY created_at DESC
LIMIT 1;

-- ===========================================
-- STEP 4: Test error state
-- ===========================================

-- Wait 2-3 seconds, then test error state
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
-- VERIFICATION QUERIES
-- ===========================================

-- Check the test run
SELECT 'Test run details' as info,
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

-- Check Realtime publication
SELECT 'Realtime publication check' as info,
       CASE 
         WHEN EXISTS (
           SELECT 1 FROM pg_publication_tables
           WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='pipeline_runs'
         ) THEN 'SUCCESS - Table in Realtime publication'
         ELSE 'FAILED - Table not in Realtime publication'
       END as result;

-- Check RLS policies
SELECT 'RLS policy check' as info,
       CASE 
         WHEN EXISTS (
           SELECT 1 FROM pg_policies
           WHERE schemaname='public' AND tablename='pipeline_runs' AND policyname='select_own_runs'
         ) THEN 'SUCCESS - RLS policy exists'
         ELSE 'FAILED - RLS policy missing'
       END as result;
