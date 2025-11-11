-- Dynamic Realtime test script
-- This script automatically finds a recording and tests status updates

-- Step 1: Find and display available recordings
SELECT 
  'Available recordings for testing' as info,
  id,
  status,
  created_at,
  user_id
FROM public.recordings 
ORDER BY created_at DESC 
LIMIT 5;

-- Step 2: Test with the most recent recording (if any exist)
DO $$
DECLARE
    test_recording_id UUID;
    test_user_id UUID;
BEGIN
    -- Get the most recent recording
    SELECT id, user_id INTO test_recording_id, test_user_id
    FROM public.recordings 
    ORDER BY created_at DESC 
    LIMIT 1;
    
    IF test_recording_id IS NULL THEN
        RAISE NOTICE 'No recordings found. Please create a recording first.';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Testing with recording ID: %', test_recording_id;
    RAISE NOTICE 'User ID: %', test_user_id;
    
    -- Test uploading status
    UPDATE public.recordings 
    SET status = 'uploading', status_changed_at = now() 
    WHERE id = test_recording_id;
    RAISE NOTICE 'Updated to uploading status';
    
    -- Wait a moment
    PERFORM pg_sleep(1);
    
    -- Test transcribing status
    UPDATE public.recordings 
    SET status = 'transcribing', status_changed_at = now() 
    WHERE id = test_recording_id;
    RAISE NOTICE 'Updated to transcribing status';
    
    -- Wait a moment
    PERFORM pg_sleep(1);
    
    -- Test summarizing status
    UPDATE public.recordings 
    SET status = 'summarizing', status_changed_at = now() 
    WHERE id = test_recording_id;
    RAISE NOTICE 'Updated to summarizing status';
    
    -- Wait a moment
    PERFORM pg_sleep(1);
    
    -- Test ready status
    UPDATE public.recordings 
    SET status = 'ready', status_changed_at = now() 
    WHERE id = test_recording_id;
    RAISE NOTICE 'Updated to ready status';
    
    -- Wait a moment
    PERFORM pg_sleep(1);
    
    -- Reset to local for testing
    UPDATE public.recordings 
    SET status = 'local', status_changed_at = now() 
    WHERE id = test_recording_id;
    RAISE NOTICE 'Reset to local status';
    
    RAISE NOTICE 'Test complete! Check Flutter console for Realtime logs.';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error during test: %', SQLERRM;
END $$;

-- Step 3: Show final status
SELECT 
  'Final status after test' as info,
  id,
  status,
  status_changed_at,
  created_at
FROM public.recordings 
ORDER BY created_at DESC 
LIMIT 1;
