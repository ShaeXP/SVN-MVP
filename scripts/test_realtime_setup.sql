-- Test script to verify Realtime setup for public.recordings
-- Run this in Supabase SQL Editor to verify everything is configured correctly

-- 1) Check if table is in Realtime publication
SELECT 
  'Table in Realtime publication' as check_name,
  CASE 
    WHEN COUNT(*) > 0 THEN 'PASS' 
    ELSE 'FAIL - Table not in publication' 
  END as result,
  COUNT(*) as count
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
  AND schemaname = 'public' 
  AND tablename = 'recordings';

-- 2) Check replica identity setting
SELECT 
  'Replica identity setting' as check_name,
  CASE 
    WHEN relreplident = 'f' THEN 'PASS - FULL replica identity' 
    ELSE 'FAIL - Not FULL replica identity' 
  END as result,
  relreplident as current_setting
FROM pg_class 
WHERE relname = 'recordings' 
  AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 3) Check RLS status
SELECT 
  'Row Level Security enabled' as check_name,
  CASE 
    WHEN relrowsecurity = true THEN 'PASS - RLS enabled' 
    ELSE 'FAIL - RLS not enabled' 
  END as result,
  relrowsecurity as current_setting
FROM pg_class 
WHERE relname = 'recordings' 
  AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 4) Check RLS policies
SELECT 
  'RLS policies' as check_name,
  CASE 
    WHEN COUNT(*) > 0 THEN 'PASS - Policies exist' 
    ELSE 'FAIL - No policies found' 
  END as result,
  COUNT(*) as policy_count,
  STRING_AGG(policyname, ', ') as policy_names
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'recordings';

-- 5) Check table structure
SELECT 
  'Table structure' as check_name,
  'PASS - Table exists' as result,
  COUNT(*) as column_count
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'recordings';

-- 6) Check for status_changed_at column
SELECT 
  'status_changed_at column' as check_name,
  CASE 
    WHEN COUNT(*) > 0 THEN 'PASS - Column exists' 
    ELSE 'FAIL - Column missing' 
  END as result,
  COUNT(*) as found
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'recordings' 
  AND column_name = 'status_changed_at';

-- 7) Check recording_status enum
SELECT 
  'recording_status enum' as check_name,
  CASE 
    WHEN COUNT(*) > 0 THEN 'PASS - Enum exists' 
    ELSE 'FAIL - Enum missing' 
  END as result,
  COUNT(*) as enum_count,
  STRING_AGG(enumlabel, ', ') as enum_values
FROM pg_enum e
JOIN pg_type t ON e.enumtypid = t.oid
WHERE t.typname = 'recording_status';

-- Summary
SELECT '=== REALTIME SETUP VERIFICATION COMPLETE ===' as summary;
