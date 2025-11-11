-- Check if the recording_status enum migration has been applied
-- Run this to see what columns and types exist in the recordings table

-- 1) Check if status_changed_at column exists
SELECT 
  'status_changed_at column' as check_name,
  CASE 
    WHEN COUNT(*) > 0 THEN 'EXISTS' 
    ELSE 'MISSING - Run migration first' 
  END as result
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'recordings' 
  AND column_name = 'status_changed_at';

-- 2) Check if recording_status enum exists
SELECT 
  'recording_status enum' as check_name,
  CASE 
    WHEN COUNT(*) > 0 THEN 'EXISTS' 
    ELSE 'MISSING - Run migration first' 
  END as result,
  STRING_AGG(enumlabel, ', ') as enum_values
FROM pg_enum e
JOIN pg_type t ON e.enumtypid = t.oid
WHERE t.typname = 'recording_status';

-- 3) Check current status column type
SELECT 
  'status column type' as check_name,
  data_type as current_type,
  CASE 
    WHEN data_type = 'USER-DEFINED' THEN 'ENUM (migration applied)'
    WHEN data_type = 'text' THEN 'TEXT (migration needed)'
    ELSE 'UNKNOWN'
  END as interpretation
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'recordings' 
  AND column_name = 'status';

-- 4) Show all columns in recordings table
SELECT 
  'All columns in recordings table' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'recordings'
ORDER BY ordinal_position;

-- 5) Check if table has any data
SELECT 
  'Table data count' as check_name,
  COUNT(*) as record_count
FROM public.recordings;
