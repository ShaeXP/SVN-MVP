-- Fix Realtime setup for pipeline animations
-- Ensure table is in Realtime publication for Postgres WAL events

-- Add recordings table to Realtime publication (idempotent)
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

-- Ensure replica identity for robust payloads (includes old values)
ALTER TABLE public.recordings REPLICA IDENTITY FULL;

-- Add comment for documentation
COMMENT ON TABLE public.recordings IS 'Recording pipeline status table - enabled for Realtime updates';
