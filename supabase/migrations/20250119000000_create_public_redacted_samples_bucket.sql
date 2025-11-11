-- Create public_redacted_samples storage bucket with path-scoped read access
-- Only allows public read on samples/** path to prevent noisy bucket-wide access
-- Service-role only writes (no anon inserts/updates/deletes)

-- Create the storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'public_redacted_samples',
  'public_redacted_samples', 
  true,  -- public bucket
  10485760,  -- 10MB file size limit
  ARRAY['application/pdf']  -- only PDF files allowed
);

-- RLS Policy: Allow public read access only for samples/** path
CREATE POLICY "Public read access for samples path only" ON storage.objects
FOR SELECT
TO anon
USING (
  bucket_id = 'public_redacted_samples' 
  AND object_name LIKE 'samples/%'
);

-- RLS Policy: Deny all anon writes (service role only)
CREATE POLICY "Deny anon writes to public samples" ON storage.objects
FOR INSERT
TO anon
WITH CHECK (false);

CREATE POLICY "Deny anon updates to public samples" ON storage.objects
FOR UPDATE
TO anon
USING (false);

CREATE POLICY "Deny anon deletes to public samples" ON storage.objects
FOR DELETE
TO anon
USING (false);

-- RLS Policy: Allow service role to write anywhere in bucket
CREATE POLICY "Allow service role writes to public samples" ON storage.objects
FOR ALL
TO service_role
USING (bucket_id = 'public_redacted_samples')
WITH CHECK (bucket_id = 'public_redacted_samples');

-- Create index for efficient path-based queries
CREATE INDEX IF NOT EXISTS idx_public_samples_path ON storage.objects (bucket_id, object_name) 
WHERE bucket_id = 'public_redacted_samples' AND object_name LIKE 'samples/%';
