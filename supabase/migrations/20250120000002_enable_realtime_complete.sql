-- Enable Realtime for public.recordings with complete setup
-- This migration ensures Postgres Changes work for pipeline animations

-- 1) Add the table to the Realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE public.recordings;

-- 2) Ensure updates include full row (helps when only some cols change)
ALTER TABLE public.recordings REPLICA IDENTITY FULL;

-- 3) Verify it's in the publication (should return one row)
-- This is just for verification - the actual check is done below
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
      AND schemaname = 'public' 
      AND tablename = 'recordings'
  ) THEN
    RAISE EXCEPTION 'Failed to add recordings table to Realtime publication';
  END IF;
END $$;

-- 4) Enable RLS if not already enabled
ALTER TABLE public.recordings ENABLE ROW LEVEL SECURITY;

-- 5) Create SELECT policy for Realtime (allows current user to see their own recordings)
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

-- 6) Add comment for documentation
COMMENT ON TABLE public.recordings IS 'Recording pipeline status table - enabled for Realtime updates with RLS policy';

-- 7) Log the setup completion
DO $$ 
BEGIN
  RAISE NOTICE 'Realtime setup complete for public.recordings';
  RAISE NOTICE 'Publication: %', (
    SELECT COUNT(*) 
    FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
      AND schemaname = 'public' 
      AND tablename = 'recordings'
  );
  RAISE NOTICE 'RLS enabled: %', (
    SELECT relrowsecurity 
    FROM pg_class 
    WHERE relname = 'recordings' 
      AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  );
END $$;
