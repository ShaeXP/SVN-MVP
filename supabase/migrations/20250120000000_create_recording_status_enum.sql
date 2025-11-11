-- Create recording_status enum with 6 canonical values
-- This replaces any ad-hoc string status values with a single source of truth

-- Create the enum type
CREATE TYPE recording_status AS ENUM (
  'local',
  'uploading', 
  'transcribing',
  'summarizing',
  'ready',
  'error'
);

-- Update recordings table to use the enum
-- First, add the new column with default value
ALTER TABLE public.recordings 
ADD COLUMN status_new recording_status DEFAULT 'local';

-- Migrate existing data (map any existing status strings to enum values)
UPDATE public.recordings 
SET status_new = CASE 
  WHEN status = 'local' THEN 'local'::recording_status
  WHEN status = 'uploading' THEN 'uploading'::recording_status
  WHEN status = 'transcribing' THEN 'transcribing'::recording_status
  WHEN status = 'summarizing' THEN 'summarizing'::recording_status
  WHEN status = 'ready' THEN 'ready'::recording_status
  WHEN status = 'error' THEN 'error'::recording_status
  -- Map any other values to 'error' (unknown states)
  ELSE 'error'::recording_status
END;

-- Add status_changed_at timestamp for UI staleness guards
ALTER TABLE public.recordings 
ADD COLUMN status_changed_at timestamptz DEFAULT now();

-- Update status_changed_at when status_new changes
CREATE OR REPLACE FUNCTION update_status_changed_at()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status_new IS DISTINCT FROM NEW.status_new THEN
    NEW.status_changed_at = now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_status_changed_at
  BEFORE UPDATE ON public.recordings
  FOR EACH ROW
  EXECUTE FUNCTION update_status_changed_at();

-- Drop the old status column and rename the new one
ALTER TABLE public.recordings DROP COLUMN status;
ALTER TABLE public.recordings RENAME COLUMN status_new TO status;

-- Add NOT NULL constraint
ALTER TABLE public.recordings ALTER COLUMN status SET NOT NULL;

-- Add CHECK constraint to ensure only valid enum values
ALTER TABLE public.recordings 
ADD CONSTRAINT recordings_status_check 
CHECK (status IN ('local', 'uploading', 'transcribing', 'summarizing', 'ready', 'error'));

-- Create index for efficient status queries
CREATE INDEX IF NOT EXISTS idx_recordings_status ON public.recordings (status);
CREATE INDEX IF NOT EXISTS idx_recordings_status_changed_at ON public.recordings (status_changed_at);

-- Update RLS policies to work with the new enum column
-- (Existing policies should continue to work as the column name is the same)
