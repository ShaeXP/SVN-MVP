-- Minimal Realtime migration - just enable Realtime for existing status column
-- This avoids all enum migration issues

-- ===========================================
-- STEP 1: Enable Realtime (this is all we need!)
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

-- Set replica identity for full payloads (includes old values)
ALTER TABLE public.recordings REPLICA IDENTITY FULL;

-- Enable RLS if not already enabled
ALTER TABLE public.recordings ENABLE ROW LEVEL SECURITY;

-- Create SELECT policy for Realtime (allows current user to see their own recordings)
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

-- Check if Realtime is enabled
SELECT 
  'Realtime Status' as check_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'recordings'
    ) THEN 'SUCCESS - Realtime enabled'
    ELSE 'FAILED - Realtime not enabled'
  END as result;

-- Check current table structure
SELECT 
  'Current Table Structure' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'recordings'
ORDER BY ordinal_position;

-- Check current status values
SELECT 
  'Current Status Values' as info,
  status,
  COUNT(*) as count
FROM public.recordings 
GROUP BY status 
ORDER BY count DESC;
