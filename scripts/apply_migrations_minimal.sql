-- Minimal migration for Realtime pipeline animations
-- This approach avoids enum casting issues by using text first

-- ===========================================
-- STEP 1: Create recording_status enum
-- ===========================================

DO $$ BEGIN
  CREATE TYPE recording_status AS ENUM (
    'local',
    'uploading', 
    'transcribing',
    'summarizing',
    'ready',
    'error'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- ===========================================
-- STEP 2: Add status_changed_at column
-- ===========================================

ALTER TABLE public.recordings ADD COLUMN IF NOT EXISTS status_changed_at timestamptz DEFAULT now();

-- ===========================================
-- STEP 3: Add new status column as TEXT first
-- ===========================================

-- Add new status column as text to avoid enum casting issues
ALTER TABLE public.recordings ADD COLUMN IF NOT EXISTS status_new TEXT;

-- Set default value
UPDATE public.recordings SET status_new = 'local' WHERE status_new IS NULL;

-- ===========================================
-- STEP 4: Migrate existing data to text column
-- ===========================================

-- Copy existing status values to new column
UPDATE public.recordings 
SET status_new = CASE 
  WHEN status::text = 'local' THEN 'local'
  WHEN status::text = 'uploading' THEN 'uploading'
  WHEN status::text = 'transcribing' THEN 'transcribing'
  WHEN status::text = 'summarizing' THEN 'summarizing'
  WHEN status::text = 'ready' THEN 'ready'
  WHEN status::text = 'error' THEN 'error'
  WHEN status::text = 'uploaded' THEN 'ready'  -- Map old 'uploaded' to 'ready'
  ELSE 'error'
END
WHERE status_new IS NULL;

-- ===========================================
-- STEP 5: Convert text column to enum
-- ===========================================

-- Now convert the text column to enum type
ALTER TABLE public.recordings ALTER COLUMN status_new TYPE recording_status USING status_new::recording_status;

-- ===========================================
-- STEP 6: Replace old status column
-- ===========================================

-- Drop old status column and rename new one
ALTER TABLE public.recordings DROP COLUMN IF EXISTS status;
ALTER TABLE public.recordings RENAME COLUMN status_new TO status;

-- Set NOT NULL
ALTER TABLE public.recordings ALTER COLUMN status SET NOT NULL;

-- ===========================================
-- STEP 7: Enable Realtime
-- ===========================================

-- Add to Realtime publication
DO $$ BEGIN
  PERFORM 1
  FROM pg_publication_tables
  WHERE pubname = 'supabase_realtime' 
    AND schemaname='public' 
    AND tablename='recordings';
  IF NOT FOUND THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.recordings';
  END IF;
END $$;

-- Set replica identity for full payloads
ALTER TABLE public.recordings REPLICA IDENTITY FULL;

-- Enable RLS
ALTER TABLE public.recordings ENABLE ROW LEVEL SECURITY;

-- Create SELECT policy for Realtime
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_policies 
    WHERE schemaname='public' 
      AND tablename='recordings' 
      AND policyname='realtime_select_own'
  ) THEN
    CREATE POLICY realtime_select_own
    ON public.recordings
    FOR SELECT
    USING ( auth.uid() = user_id );
  END IF;
END $$;

-- ===========================================
-- STEP 8: Create indexes
-- ===========================================

CREATE INDEX IF NOT EXISTS idx_recordings_status ON public.recordings (status);
CREATE INDEX IF NOT EXISTS idx_recordings_status_changed_at ON public.recordings (status_changed_at);

-- ===========================================
-- VERIFICATION
-- ===========================================

-- Check final result
SELECT 
  'Migration Complete' as status,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
        AND table_name = 'recordings' 
        AND column_name = 'status_changed_at'
    ) AND EXISTS (
      SELECT 1 FROM pg_enum e
      JOIN pg_type t ON e.enumtypid = t.oid
      WHERE t.typname = 'recording_status'
    ) AND EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'recordings'
    ) THEN 'SUCCESS'
    ELSE 'FAILED'
  END as result;

-- Show final table structure
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'recordings'
ORDER BY ordinal_position;
