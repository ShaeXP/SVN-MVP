-- Complete setup and test for pipeline_runs table
-- This script creates the table, enables Realtime, and tests with your recording ID

-- ===========================================
-- STEP 1: Create pipeline_runs table
-- ===========================================

CREATE TABLE IF NOT EXISTS public.pipeline_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recording_id uuid NOT NULL REFERENCES public.recordings(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,                                  -- for RLS
  stage text NOT NULL CHECK (stage IN ('queued','uploading','transcribing','summarizing','ready','error')),
  progress real CHECK (progress >= 0 AND progress <= 1),  -- nullable; null = indeterminate
  step int NOT NULL DEFAULT 0,                            -- monotonic step to ignore stale/out-of-order events
  message text,                                           -- optional human hint
  trace_id text,                                          -- for logs
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ===========================================
-- STEP 2: Enable Realtime streaming
-- ===========================================

-- Add to Realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE public.pipeline_runs;

-- Ensure full old/new rows on updates (useful for clients)
ALTER TABLE public.pipeline_runs REPLICA IDENTITY FULL;

-- ===========================================
-- STEP 3: Enable RLS
-- ===========================================

-- Enable RLS
ALTER TABLE public.pipeline_runs ENABLE ROW LEVEL SECURITY;

-- Create SELECT policy for owner
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
-- STEP 4: Create indexes for performance
-- ===========================================

-- Index for efficient queries by recording_id
CREATE INDEX IF NOT EXISTS idx_pipeline_runs_recording_id ON public.pipeline_runs (recording_id);

-- Index for efficient queries by user_id (for RLS)
CREATE INDEX IF NOT EXISTS idx_pipeline_runs_user_id ON public.pipeline_runs (user_id);

-- Index for efficient queries by stage
CREATE INDEX IF NOT EXISTS idx_pipeline_runs_stage ON public.pipeline_runs (stage);

-- Index for efficient queries by created_at (for ordering)
CREATE INDEX IF NOT EXISTS idx_pipeline_runs_created_at ON public.pipeline_runs (created_at);

-- ===========================================
-- STEP 5: Add trigger to update updated_at
-- ===========================================

-- Create function to update updated_at
CREATE OR REPLACE FUNCTION update_pipeline_runs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_pipeline_runs_updated_at ON public.pipeline_runs;
CREATE TRIGGER trigger_update_pipeline_runs_updated_at
  BEFORE UPDATE ON public.pipeline_runs
  FOR EACH ROW
  EXECUTE FUNCTION update_pipeline_runs_updated_at();

-- ===========================================
-- STEP 6: Create a test pipeline run
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
-- STEP 7: Test Realtime with status progression
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

-- ===========================================
-- VERIFICATION
-- ===========================================

-- Check table was created
SELECT 'Table created' as info,
       column_name,
       data_type,
       is_nullable,
       column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'pipeline_runs'
ORDER BY ordinal_position;

-- Check Realtime publication
SELECT 'Realtime publication' as info,
       CASE 
         WHEN EXISTS (
           SELECT 1 FROM pg_publication_tables
           WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='pipeline_runs'
         ) THEN 'SUCCESS - Table in Realtime publication'
         ELSE 'FAILED - Table not in Realtime publication'
       END as result;

-- Check RLS policies
SELECT 'RLS policies' as info,
       CASE 
         WHEN EXISTS (
           SELECT 1 FROM pg_policies
           WHERE schemaname='public' AND tablename='pipeline_runs' AND policyname='select_own_runs'
         ) THEN 'SUCCESS - RLS policy exists'
         ELSE 'FAILED - RLS policy missing'
       END as result;

-- Check the test run
SELECT 'Test run created' as info,
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
