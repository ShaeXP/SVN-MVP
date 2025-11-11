-- Simple Realtime test - just run this one query
-- This will test Realtime with the most recent recording

UPDATE public.recordings 
SET status = 'transcribing', status_changed_at = now() 
WHERE id = (
  SELECT id 
  FROM public.recordings 
  ORDER BY created_at DESC 
  LIMIT 1
);

-- If you get an error "no rows affected", it means no recordings exist yet.
-- Create a recording first by using the Flutter app, then run this test.
