-- Debug Realtime test - run this after applying migrations
-- This will help verify Realtime is working

-- 1) Check if migrations were applied
SELECT 
  'Migration Status' as check_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
        AND table_name = 'recordings' 
        AND column_name = 'status_changed_at'
    ) THEN 'status_changed_at column exists'
    ELSE 'status_changed_at column MISSING'
  END as result;

-- 2) Check if Realtime publication is set up
SELECT 
  'Realtime Publication' as check_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'recordings'
    ) THEN 'recordings table in Realtime publication'
    ELSE 'recordings table NOT in Realtime publication'
  END as result;

-- 3) Check current recordings
SELECT 
  'Current Recordings' as info,
  COUNT(*) as count,
  STRING_AGG(status, ', ') as statuses
FROM public.recordings;

-- 4) Test with a simple update (if recordings exist)
DO $$
DECLARE
    test_id UUID;
BEGIN
    -- Get the most recent recording
    SELECT id INTO test_id
    FROM public.recordings 
    ORDER BY created_at DESC 
    LIMIT 1;
    
    IF test_id IS NOT NULL THEN
        -- Update status to trigger Realtime event
        UPDATE public.recordings 
        SET status = 'transcribing', status_changed_at = now() 
        WHERE id = test_id;
        
        RAISE NOTICE 'Updated recording % to transcribing status', test_id;
        RAISE NOTICE 'Check Flutter console for [REALTIME] logs';
    ELSE
        RAISE NOTICE 'No recordings found. Create a recording first using the Flutter app.';
    END IF;
END $$;

-- 5) Show final status
SELECT 
  'Final Status' as info,
  id,
  status,
  status_changed_at,
  created_at
FROM public.recordings 
ORDER BY created_at DESC 
LIMIT 1;
