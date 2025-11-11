-- Complete Realtime migration with enum repair
-- Handles all cases: enum exists/doesn't, column exists/doesn't, values missing, etc.

-- ===========================================
-- INSPECTION (run these first to see current state)
-- ===========================================

-- What values does the enum currently have?
SELECT 'Current enum values' as info, e.enumlabel
FROM pg_type t
JOIN pg_enum e ON e.enumtypid = t.oid
WHERE t.typname = 'recording_status'
ORDER BY e.enumsortorder;

-- What distinct values exist in the table now?
SELECT 'Current table values' as info, DISTINCT status::text as status_text 
FROM public.recordings;

-- ===========================================
-- SINGLE TRANSACTION REPAIR + MIGRATION
-- ===========================================

BEGIN;

-- 1) Create type if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type WHERE typname = 'recording_status'
  ) THEN
    CREATE TYPE recording_status AS ENUM (
      'local',
      'uploading',
      'transcribing',
      'summarizing',
      'ready',
      'error'
    );
  END IF;
END $$;

-- 2) Ensure ALL required values exist on the enum (old enum may be missing 'local', etc.)
-- Note: IF NOT EXISTS is supported on Supabase PG. Order is not critical, but we add a consistent order.
ALTER TYPE recording_status ADD VALUE IF NOT EXISTS 'local';
ALTER TYPE recording_status ADD VALUE IF NOT EXISTS 'uploading';
ALTER TYPE recording_status ADD VALUE IF NOT EXISTS 'transcribing';
ALTER TYPE recording_status ADD VALUE IF NOT EXISTS 'summarizing';
ALTER TYPE recording_status ADD VALUE IF NOT EXISTS 'ready';
ALTER TYPE recording_status ADD VALUE IF NOT EXISTS 'error';

-- 3) Add status_changed_at if missing
ALTER TABLE public.recordings
  ADD COLUMN IF NOT EXISTS status_changed_at timestamptz DEFAULT now();

-- 4) Normalize data into a temporary TEXT column (avoids 22P02 during cast)
ALTER TABLE public.recordings
  ADD COLUMN IF NOT EXISTS status_tmp text;

-- Seed tmp from existing status (whatever its type is)
UPDATE public.recordings
SET status_tmp = COALESCE(status::text, status_tmp)
WHERE status_tmp IS NULL;

-- 5) Map ANY legacy/unknown strings into our canonical 6 before the cast
UPDATE public.recordings
SET status_tmp = CASE LOWER(status_tmp)
  WHEN 'local' THEN 'local'
  WHEN 'uploading' THEN 'uploading'
  WHEN 'uploaded' THEN 'ready'
  WHEN 'transcribing' THEN 'transcribing'
  WHEN 'summarizing' THEN 'summarizing'
  WHEN 'ready' THEN 'ready'
  WHEN 'error' THEN 'error'
  ELSE 'error'  -- force anything else to 'error' so the cast cannot fail
END;

-- 6) Ensure the real status column exists and is typed correctly
-- If the real column doesn't exist, create it as enum.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='recordings' AND column_name='status'
  ) THEN
    ALTER TABLE public.recordings
      ADD COLUMN status recording_status NOT NULL DEFAULT 'local';
  END IF;
END $$;

-- If status exists but not enum, convert using the tmp column (safe cast now)
DO $$
DECLARE coltype text;
BEGIN
  SELECT data_type INTO coltype
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='recordings' AND column_name='status';

  IF coltype IS NULL THEN
    -- created above as enum; seed from tmp
    UPDATE public.recordings SET status = status_tmp::recording_status;
  ELSIF coltype <> 'USER-DEFINED' THEN
    -- it's not an enum yet → alter type using mapped tmp
    ALTER TABLE public.recordings
      ALTER COLUMN status TYPE recording_status
      USING status_tmp::recording_status;
  ELSE
    -- it's already an enum; just ensure all rows map
    UPDATE public.recordings SET status = status_tmp::recording_status;
  END IF;
END $$;

-- 7) Clean up helper column
ALTER TABLE public.recordings DROP COLUMN IF EXISTS status_tmp;

-- 8) Realtime plumbing (idempotent)
-- Put the table in the publication (so updates stream)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname='supabase_realtime'
      AND schemaname='public'
      AND tablename='recordings'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.recordings';
  END IF;
END $$;

-- Ensure full old/new rows on updates (useful for clients)
ALTER TABLE public.recordings REPLICA IDENTITY FULL;

-- RLS: allow select for owner (adjust user_id column name if different)
ALTER TABLE public.recordings ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='recordings' AND policyname='realtime_select_own'
  ) THEN
    CREATE POLICY realtime_select_own
    ON public.recordings
    FOR SELECT
    USING (auth.uid() = user_id);
  END IF;
END $$;

COMMIT;

-- ===========================================
-- VERIFICATION
-- ===========================================

-- Check final enum values
SELECT 'Final enum values' as info, e.enumlabel
FROM pg_type t
JOIN pg_enum e ON e.enumtypid = t.oid
WHERE t.typname = 'recording_status'
ORDER BY e.enumsortorder;

-- Check final table structure
SELECT 'Final table structure' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'recordings'
ORDER BY ordinal_position;

-- Check Realtime publication
SELECT 'Realtime publication' as info,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname='supabase_realtime'
        AND schemaname='public'
        AND tablename='recordings'
    ) THEN 'SUCCESS - Table in Realtime publication'
    ELSE 'FAILED - Table not in Realtime publication'
  END as result;

-- Check RLS policies
SELECT 'RLS policies' as info,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname='public' AND tablename='recordings' AND policyname='realtime_select_own'
    ) THEN 'SUCCESS - RLS policy exists'
    ELSE 'FAILED - RLS policy missing'
  END as result;
