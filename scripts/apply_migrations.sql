-- Apply all migrations for Realtime pipeline animations
-- Run this entire script in Supabase SQL Editor

-- ===========================================
-- MIGRATION 1: Create recording_status enum
-- ===========================================

-- Create the enum type
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

-- Add status_changed_at column if it doesn't exist
ALTER TABLE public.recordings ADD COLUMN IF NOT EXISTS status_changed_at timestamptz DEFAULT now();

-- Update recordings table to use the enum
-- First, add the new column with default value
ALTER TABLE public.recordings ADD COLUMN IF NOT EXISTS status_new recording_status DEFAULT 'local';

-- Migrate existing data (map any existing status strings to enum values)
UPDATE public.recordings 
SET status_new = CASE 
  WHEN status = 'local' THEN 'local'::recording_status
  WHEN status = 'uploading' THEN 'uploading'::recording_status
  WHEN status = 'transcribing' THEN 'transcribing'::recording_status
  WHEN status = 'summarizing' THEN 'summarizing'::recording_status
  WHEN status = 'ready' THEN 'ready'::recording_status
  WHEN status = 'error' THEN 'error'::recording_status
  -- Map any other values to 'error' (unknown states)
  ELSE 'error'::recording_status
END;

-- Drop the old status column and rename the new one
ALTER TABLE public.recordings DROP COLUMN IF EXISTS status;
ALTER TABLE public.recordings RENAME COLUMN status_new TO status;

-- Add NOT NULL constraint
ALTER TABLE public.recordings ALTER COLUMN status SET NOT NULL;

-- Add CHECK constraint to ensure only valid enum values
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'recordings_status_check' 
    AND conrelid = 'public.recordings'::regclass
  ) THEN
    ALTER TABLE public.recordings 
    ADD CONSTRAINT recordings_status_check 
    CHECK (status IN ('local', 'uploading', 'transcribing', 'summarizing', 'ready', 'error'));
  END IF;
END $$;

-- Create index for efficient status queries
CREATE INDEX IF NOT EXISTS idx_recordings_status ON public.recordings (status);
CREATE INDEX IF NOT EXISTS idx_recordings_status_changed_at ON public.recordings (status_changed_at);

-- ===========================================
-- MIGRATION 2: Enable Realtime
-- ===========================================

-- Add recordings table to Realtime publication
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

-- Ensure replica identity for robust payloads
ALTER TABLE public.recordings REPLICA IDENTITY FULL;

-- Enable RLS if not already enabled
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
-- VERIFICATION
-- ===========================================

-- Check if everything was applied correctly
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
    ) THEN 'SUCCESS - All migrations applied'
    ELSE 'FAILED - Check individual components'
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
