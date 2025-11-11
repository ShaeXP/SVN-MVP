-- Final migration: Normalize to 6 canonical statuses and enforce enum type
-- This ensures no bad values slip in again and Realtime works properly

-- ===========================================
-- STEP 1: Ensure the enum exists and includes all 6 values
-- ===========================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'recording_status') THEN
    CREATE TYPE recording_status AS ENUM ('local','uploading','transcribing','summarizing','ready','error');
  END IF;
END $$;

ALTER TYPE recording_status ADD VALUE IF NOT EXISTS 'local';
ALTER TYPE recording_status ADD VALUE IF NOT EXISTS 'uploading';
ALTER TYPE recording_status ADD VALUE IF NOT EXISTS 'transcribing';
ALTER TYPE recording_status ADD VALUE IF NOT EXISTS 'summarizing';
ALTER TYPE recording_status ADD VALUE IF NOT EXISTS 'ready';
ALTER TYPE recording_status ADD VALUE IF NOT EXISTS 'error';

-- ===========================================
-- STEP 2: Normalize existing rows (map legacy → canonical), then cast the column to enum
-- ===========================================

-- Helper temp column to avoid 22P02 during cast
ALTER TABLE public.recordings
  ADD COLUMN IF NOT EXISTS status_tmp text;

-- Seed from current status (whatever type it is)
UPDATE public.recordings
SET status_tmp = COALESCE(status::text, status_tmp)
WHERE status_tmp IS NULL;

-- Map everything into the canonical 6 BEFORE the cast
UPDATE public.recordings
SET status_tmp = CASE LOWER(status_tmp)
  WHEN 'uploaded'      THEN 'ready'        -- legacy → canonical
  WHEN 'uploading'     THEN 'uploading'
  WHEN 'transcribing'  THEN 'transcribing'
  WHEN 'summarizing'   THEN 'summarizing'
  WHEN 'ready'         THEN 'ready'
  WHEN 'error'         THEN 'error'
  WHEN 'local'         THEN 'local'
  WHEN ''              THEN 'error'
  WHEN NULL            THEN 'local'
  ELSE 'error'
END;

-- Make sure the real column exists and is enum-typed
DO $$
DECLARE is_enum boolean;
BEGIN
  -- Create the column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='recordings' AND column_name='status'
  ) THEN
    ALTER TABLE public.recordings
      ADD COLUMN status recording_status NOT NULL DEFAULT 'local';
  END IF;

  -- If it's not enum yet, convert with USING from the normalized tmp
  SELECT (data_type = 'USER-DEFINED') INTO is_enum
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='recordings' AND column_name='status';

  IF is_enum IS DISTINCT FROM TRUE THEN
    ALTER TABLE public.recordings
      ALTER COLUMN status TYPE recording_status
      USING status_tmp::recording_status;
  ELSE
    -- already enum; still align values
    UPDATE public.recordings
    SET status = status_tmp::recording_status;
  END IF;

  -- Enforce NOT NULL + sensible default for new rows
  ALTER TABLE public.recordings
    ALTER COLUMN status SET NOT NULL,
    ALTER COLUMN status SET DEFAULT 'local';
END $$;

-- Clean up
ALTER TABLE public.recordings DROP COLUMN IF EXISTS status_tmp;

-- Optional: timestamp column for UI staleness/progress
ALTER TABLE public.recordings
  ADD COLUMN IF NOT EXISTS status_changed_at timestamptz DEFAULT now();

-- ===========================================
-- STEP 3: Realtime plumbing (idempotent; run once)
-- ===========================================

-- Put table into the Realtime publication so UPDATEs stream
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='recordings'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.recordings';
  END IF;
END $$;

-- Ensure payloads have full old/new row on updates
ALTER TABLE public.recordings REPLICA IDENTITY FULL;

-- RLS (adjust to your schema; temporary permissive policy if needed during testing)
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

-- ===========================================
-- STEP 4: Verification (should now show only canonical values)
-- ===========================================

-- Check distinct status values (should only show canonical 6)
SELECT 'Distinct status values after normalization' as info, 
       DISTINCT status::text AS status_text
FROM public.recordings
ORDER BY 1;

-- Check column type and constraints
SELECT 'Status column info' as info,
       column_name, 
       data_type, 
       column_default, 
       is_nullable
FROM information_schema.columns
WHERE table_schema='public' AND table_name='recordings' AND column_name='status';

-- Check Realtime publication status
SELECT 'Realtime publication status' as info,
       CASE 
         WHEN EXISTS (
           SELECT 1 FROM pg_publication_tables
           WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='recordings'
         ) THEN 'SUCCESS - Table in Realtime publication'
         ELSE 'FAILED - Table not in Realtime publication'
       END as result;

-- Check RLS policies
SELECT 'RLS policy status' as info,
       CASE 
         WHEN EXISTS (
           SELECT 1 FROM pg_policies
           WHERE schemaname='public' AND tablename='recordings' AND policyname='realtime_select_own'
         ) THEN 'SUCCESS - RLS policy exists'
         ELSE 'FAILED - RLS policy missing'
       END as result;

-- ===========================================
-- STEP 5: Test Realtime (run this after migration)
-- ===========================================

-- Get a recording ID to test with
SELECT 'Test recording ID' as info, 
       id, 
       status, 
       created_at
FROM public.recordings 
ORDER BY created_at DESC 
LIMIT 1;

-- Uncomment and run this to test Realtime (replace with actual ID):
/*
UPDATE public.recordings
SET status='transcribing', status_changed_at=now()
WHERE id='YOUR-RECORDING-ID';
*/

-- Expected result: You should see [REALTIME] logs in Flutter console
