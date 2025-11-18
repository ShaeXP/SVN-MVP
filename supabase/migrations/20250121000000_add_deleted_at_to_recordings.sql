-- Add soft-delete support to recordings table
-- This allows safe deletion without breaking foreign keys or analytics

-- Add deleted_at column (nullable, so existing records are not deleted)
ALTER TABLE public.recordings 
ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- Create index for efficient filtering of non-deleted records
CREATE INDEX IF NOT EXISTS idx_recordings_deleted_at ON public.recordings (deleted_at) 
WHERE deleted_at IS NULL;

-- Add comment for documentation
COMMENT ON COLUMN public.recordings.deleted_at IS 
'Timestamp when the recording was soft-deleted. NULL means the recording is active.';

