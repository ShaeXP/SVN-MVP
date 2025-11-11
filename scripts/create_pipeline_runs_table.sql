-- Create pipeline_runs table for UI state streaming
-- This separates UI progress from the main recordings table

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

-- Check indexes
SELECT 'Indexes created' as info,
       indexname,
       indexdef
FROM pg_indexes 
WHERE tablename = 'pipeline_runs' 
  AND schemaname = 'public'
ORDER BY indexname;
