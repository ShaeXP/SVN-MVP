-- Basic Realtime test without status_changed_at column
-- Use this if the migration hasn't been applied yet

-- Test with the most recent recording (if any exist)
UPDATE public.recordings 
SET status = 'transcribing' 
WHERE id = (
  SELECT id 
  FROM public.recordings 
  ORDER BY created_at DESC 
  LIMIT 1
);

-- If you get "no rows affected", create a recording first using the Flutter app
