-- ============================================================================
-- TEST DATABASE FIX SCRIPT
-- ============================================================================
-- Run this after applying PRODUCTION_DATABASE_FIX.sql to verify everything works

-- ============================================================================
-- TEST 1: Verify job_category_name column exists and is populated
-- ============================================================================

SELECT 
    'TEST 1: Job Category Name Column' as test_name,
    COUNT(*) as total_jobs,
    COUNT(job_category_name) as jobs_with_category_name,
    COUNT(CASE WHEN job_category_name IS NULL OR job_category_name = '' THEN 1 END) as jobs_without_category_name
FROM jobs;

-- ============================================================================
-- TEST 2: Show sample job data with categories
-- ============================================================================

SELECT 
    'TEST 2: Sample Job Data' as test_name,
    title,
    job_type,
    job_category_name,
    created_at
FROM jobs 
ORDER BY created_at DESC 
LIMIT 3;

-- ============================================================================
-- TEST 3: Check helper preferences
-- ============================================================================

SELECT 
    'TEST 3: Helper Preferences' as test_name,
    u.first_name,
    u.last_name,
    ARRAY_AGG(jc.name) as preferred_categories
FROM users u
JOIN helper_job_types hjt ON u.id = hjt.helper_id
JOIN job_categories jc ON hjt.job_category_id = jc.id
WHERE u.user_type = 'helper'
GROUP BY u.id, u.first_name, u.last_name
ORDER BY u.first_name
LIMIT 3;

-- ============================================================================
-- TEST 4: Test helper filtering function
-- ============================================================================

-- Get a sample helper ID
WITH sample_helper AS (
    SELECT u.id as helper_id, u.first_name, u.last_name
    FROM users u
    JOIN helper_job_types hjt ON u.id = hjt.helper_id
    WHERE u.user_type = 'helper'
    LIMIT 1
)
SELECT 
    'TEST 4: Helper Filtering Function' as test_name,
    h.first_name || ' ' || h.last_name as helper_name,
    get_helper_job_categories(h.helper_id) as helper_categories,
    (SELECT COUNT(*) FROM get_public_jobs_for_helper(h.helper_id)) as matching_public_jobs
FROM sample_helper h;

-- ============================================================================
-- TEST 5: Verify functions exist
-- ============================================================================

SELECT 
    'TEST 5: Database Functions' as test_name,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN (
    'get_helper_job_categories',
    'get_public_jobs_for_helper', 
    'get_private_jobs_for_helper',
    'create_job_with_helpee_details',
    'auto_populate_job_category_name'
)
ORDER BY routine_name;

-- ============================================================================
-- TEST 6: Verify trigger exists
-- ============================================================================

SELECT 
    'TEST 6: Trigger Verification' as test_name,
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name = 'auto_populate_job_category_name_trigger';

-- ============================================================================
-- EXPECTED RESULTS SUMMARY
-- ============================================================================

/*
Expected Results:

TEST 1: Should show all jobs have job_category_name populated
TEST 2: Should show recent jobs with category names like "Baby Care", "Gardening", etc.
TEST 3: Should show helpers with their preferred job categories
TEST 4: Should show a helper and their matching job count (could be 0 if no matches)
TEST 5: Should show all 5 functions exist
TEST 6: Should show the trigger exists on jobs table

If any test fails, check the PRODUCTION_DATABASE_FIX.sql was applied correctly.
*/ 