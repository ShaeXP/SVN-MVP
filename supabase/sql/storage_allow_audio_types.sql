-- Allow MP3 and WAV in Storage bucket without removing existing types
-- This script adds audio/mpeg (MP3) and audio/wav (WAV) to the recordings bucket
-- while preserving all existing allowed MIME types.

-- First, check the current bucket configuration
SELECT id, allowed_mime_types, file_size_limit
FROM storage.buckets
WHERE id = 'recordings';

-- Update the recordings bucket to include MP3 and WAV support
-- This uses a UNION to add new types without removing existing ones
UPDATE storage.buckets
SET allowed_mime_types = (
  SELECT array_agg(DISTINCT x)
  FROM (
    SELECT unnest(COALESCE(allowed_mime_types, '{}')) as x
    UNION ALL SELECT 'audio/mpeg'  -- mp3
    UNION ALL SELECT 'audio/wav'   -- wav
  ) s
)
WHERE id = 'recordings';

-- Verify the update
SELECT id, allowed_mime_types
FROM storage.buckets
WHERE id = 'recordings';
