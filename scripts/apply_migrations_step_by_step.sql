-- Step-by-step migration for Realtime pipeline animations
-- Run each section separately in Supabase SQL Editor

-- ===========================================
-- STEP 1: Create recording_status enum
-- ===========================================

-- Create the enum type (ignore if already exists)
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

-- Verify enum was created
SELECT 'Enum created' as status, typname as enum_name 
FROM pg_type WHERE typname = 'recording_status';

-- ===========================================
-- STEP 2: Add status_changed_at column
-- ===========================================

-- Add status_changed_at column if it doesn't exist
ALTER TABLE public.recordings ADD COLUMN IF NOT EXISTS status_changed_at timestamptz DEFAULT now();

-- Verify column was added
SELECT 'Column added' as status, column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'recordings' 
  AND column_name = 'status_changed_at';

-- ===========================================
-- STEP 3: Check current status column
-- ===========================================

-- Check what the current status column looks like
SELECT 'Current status column' as info, 
       column_name, 
       data_type, 
       is_nullable,
       column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'recordings' 
  AND column_name = 'status';

-- Check current status values
SELECT 'Current status values' as info, 
       status, 
       COUNT(*) as count
FROM public.recordings 
GROUP BY status 
ORDER BY count DESC;

-- ===========================================
-- STEP 4: Create new status column with enum type
-- ===========================================

-- Add new status column with enum type (no default to avoid casting issues)
ALTER TABLE public.recordings ADD COLUMN IF NOT EXISTS status_new recording_status;

-- Verify new column was created
SELECT 'New column created' as status, column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'recordings' 
  AND column_name = 'status_new';

-- ===========================================
-- STEP 5: Migrate data (run this only if you have data)
-- ===========================================

-- Only run this if you have existing recordings
-- First check if there are any records
SELECT 'Record count' as info, COUNT(*) as total_records FROM public.recordings;

-- If you have records, uncomment and run this migration:
/*
UPDATE public.recordings 
SET status_new = CASE 
  WHEN status::text = 'local' THEN 'local'::recording_status
  WHEN status::text = 'uploading' THEN 'uploading'::recording_status
  WHEN status::text = 'transcribing' THEN 'transcribing'::recording_status
  WHEN status::text = 'summarizing' THEN 'summarizing'::recording_status
  WHEN status::text = 'ready' THEN 'ready'::recording_status
  WHEN status::text = 'error' THEN 'error'::recording_status
  WHEN status::text = 'uploaded' THEN 'ready'::recording_status
  ELSE 'error'::recording_status
END
WHERE status_new IS NULL;
*/

-- ===========================================
-- STEP 6: Replace old status column (run this after step 5)
-- ===========================================

-- Drop old status column and rename new one
-- ALTER TABLE public.recordings DROP COLUMN IF EXISTS status;
-- ALTER TABLE public.recordings RENAME COLUMN status_new TO status;

-- Set NOT NULL
-- ALTER TABLE public.recordings ALTER COLUMN status SET NOT NULL;

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
-- FINAL VERIFICATION
-- ===========================================

-- Check migration status
SELECT 
  'Migration Status' as check_name,
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
    ELSE 'INCOMPLETE'
  END as result;
