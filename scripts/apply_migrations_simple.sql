-- Simple migration script for Realtime pipeline animations
-- Run this entire script in Supabase SQL Editor

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

-- ===========================================
-- STEP 2: Add status_changed_at column
-- ===========================================

-- Add status_changed_at column if it doesn't exist
ALTER TABLE public.recordings ADD COLUMN IF NOT EXISTS status_changed_at timestamptz DEFAULT now();

-- ===========================================
-- STEP 3: Update status column to use enum
-- ===========================================

-- Add new status column with enum type
ALTER TABLE public.recordings ADD COLUMN IF NOT EXISTS status_new recording_status DEFAULT 'local';

-- Migrate existing data (handle any existing status values)
UPDATE public.recordings 
SET status_new = CASE 
  WHEN status::text = 'local' THEN 'local'::recording_status
  WHEN status::text = 'uploading' THEN 'uploading'::recording_status
  WHEN status::text = 'transcribing' THEN 'transcribing'::recording_status
  WHEN status::text = 'summarizing' THEN 'summarizing'::recording_status
  WHEN status::text = 'ready' THEN 'ready'::recording_status
  WHEN status::text = 'error' THEN 'error'::recording_status
  WHEN status::text = 'uploaded' THEN 'ready'::recording_status  -- Map old 'uploaded' to 'ready'
  ELSE 'error'::recording_status
END;

-- Drop old status column and rename new one
ALTER TABLE public.recordings DROP COLUMN IF EXISTS status;
ALTER TABLE public.recordings RENAME COLUMN status_new TO status;

-- Set NOT NULL
ALTER TABLE public.recordings ALTER COLUMN status SET NOT NULL;

-- ===========================================
-- STEP 4: Enable Realtime
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
-- STEP 5: Create indexes
-- ===========================================

CREATE INDEX IF NOT EXISTS idx_recordings_status ON public.recordings (status);
CREATE INDEX IF NOT EXISTS idx_recordings_status_changed_at ON public.recordings (status_changed_at);

-- ===========================================
-- VERIFICATION
-- ===========================================

-- Check migration status
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
