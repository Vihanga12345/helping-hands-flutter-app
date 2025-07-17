-- ============================================================================
-- FINAL FIX: Helper Job Filtering - Only Show Jobs for Selected Categories
-- File: 048_fix_helper_job_filtering_final.sql
-- Date: 2025-01-10
-- Purpose: Fix the critical bug where helpers see jobs for categories they haven't selected
-- ============================================================================

-- The issue: Helpers are seeing ALL jobs instead of only jobs for categories 
-- they have selected (where is_active = true in helper_job_types table)

-- Root cause: get_public_jobs_for_helper() function is not properly filtering
-- by helper's active job categories in helper_job_types table

-- ============================================================================
-- STEP 1: Drop and recreate the filtering function correctly
-- ============================================================================

-- Drop existing broken function
DROP FUNCTION IF EXISTS get_public_jobs_for_helper(UUID);

-- Create the CORRECT filtering function
CREATE OR REPLACE FUNCTION get_public_jobs_for_helper(p_helper_id UUID)
RETURNS TABLE (
    id UUID,
    title VARCHAR(200),
    description TEXT,
    hourly_rate DECIMAL(10,2),
    scheduled_date DATE,
    scheduled_time TIME,
    location_address TEXT,
    status VARCHAR(20),
    created_at TIMESTAMPTZ,
    is_private BOOLEAN,
    job_category_name VARCHAR(100),
    helpee_id UUID,
    helpee_first_name VARCHAR(50),
    helpee_last_name VARCHAR(50),
    helpee_location_city VARCHAR(100),
    category_id UUID
) AS $$
DECLARE
    FOUND INTEGER;
BEGIN
    -- Debug: Show helper's active categories
    RAISE NOTICE 'Getting public jobs for helper: %', p_helper_id;
    RAISE NOTICE 'Helper active categories: %', (
        SELECT STRING_AGG(jc.name, ', ')
        FROM helper_job_types hjt
        JOIN job_categories jc ON hjt.job_category_id = jc.id
        WHERE hjt.helper_id = p_helper_id AND hjt.is_active = true
    );

    -- Return ONLY jobs that match helper's ACTIVE categories
    RETURN QUERY
    SELECT 
        j.id,
        j.title,
        j.description,
        j.hourly_rate,
        j.scheduled_date,
        j.scheduled_time,
        j.location_address,
        j.status,
        j.created_at,
        j.is_private,
        j.job_category_name,
        j.helpee_id,
        u.first_name as helpee_first_name,
        u.last_name as helpee_last_name,
        u.location_city as helpee_location_city,
        j.category_id
    FROM jobs j
    JOIN users u ON j.helpee_id = u.id
    WHERE j.is_private = false
      AND j.status = 'pending'
      AND j.assigned_helper_id IS NULL
      AND j.helpee_id != p_helper_id  -- Don't show helper their own jobs
      -- CRITICAL FILTER: Only jobs where helper has ACTIVE category
      AND EXISTS (
          SELECT 1 
          FROM helper_job_types hjt
          JOIN job_categories jc ON hjt.job_category_id = jc.id
          WHERE hjt.helper_id = p_helper_id
            AND hjt.is_active = true  -- CRITICAL: Only active categories
            AND (
                -- Match by category_id (preferred)
                jc.id = j.category_id OR 
                -- Or match by category name (fallback)
                jc.name = j.job_category_name
            )
      )
      -- Exclude jobs the helper has ignored
      AND NOT EXISTS (
          SELECT 1 FROM job_ignores ji 
          WHERE ji.job_id = j.id AND ji.helper_id = p_helper_id
      )
    ORDER BY j.created_at DESC;

    -- Debug: Show how many jobs were returned
    GET DIAGNOSTICS FOUND = ROW_COUNT;
    RAISE NOTICE 'Returning % filtered jobs for helper %', FOUND, p_helper_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also fix the private jobs function
DROP FUNCTION IF EXISTS get_private_jobs_for_helper(UUID);

CREATE OR REPLACE FUNCTION get_private_jobs_for_helper(p_helper_id UUID)
RETURNS TABLE (
    id UUID,
    title VARCHAR(200),
    description TEXT,
    hourly_rate DECIMAL(10,2),
    scheduled_date DATE,
    scheduled_time TIME,
    location_address TEXT,
    status VARCHAR(20),
    created_at TIMESTAMPTZ,
    is_private BOOLEAN,
    job_category_name VARCHAR(100),
    helpee_id UUID,
    helpee_first_name VARCHAR(50),
    helpee_last_name VARCHAR(50),
    helpee_location_city VARCHAR(100),
    category_id UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        j.id,
        j.title,
        j.description,
        j.hourly_rate,
        j.scheduled_date,
        j.scheduled_time,
        j.location_address,
        j.status,
        j.created_at,
        j.is_private,
        j.job_category_name,
        j.helpee_id,
        u.first_name as helpee_first_name,
        u.last_name as helpee_last_name,
        u.location_city as helpee_location_city,
        j.category_id
    FROM jobs j
    JOIN users u ON j.helpee_id = u.id
    WHERE j.is_private = true
      AND j.assigned_helper_id = p_helper_id
      AND j.status = 'pending'
      -- CRITICAL FILTER: Only jobs where helper has ACTIVE category
      AND EXISTS (
          SELECT 1 
          FROM helper_job_types hjt
          JOIN job_categories jc ON hjt.job_category_id = jc.id
          WHERE hjt.helper_id = p_helper_id
            AND hjt.is_active = true  -- CRITICAL: Only active categories
            AND (
                jc.id = j.category_id OR 
                jc.name = j.job_category_name
            )
      )
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STEP 2: Grant permissions
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_public_jobs_for_helper(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_private_jobs_for_helper(UUID) TO authenticated;

-- ============================================================================
-- STEP 3: Test with the specific helper from the screenshots
-- ============================================================================

DO $$
DECLARE
    test_helper_id UUID := '29e2adb3-4910-4c83-804b-0014b1c4598a';
    active_categories_count INTEGER;
    jobs_visible_count INTEGER;
    cat_record RECORD;
    job_record RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔍 TESTING HELPER JOB FILTERING FIX';
    RAISE NOTICE '=====================================';
    RAISE NOTICE 'Helper ID: %', test_helper_id;
    
    -- Show helper's job category preferences
    RAISE NOTICE '';
    RAISE NOTICE 'Helper Job Category Preferences:';
    FOR cat_record IN 
        SELECT jc.name, hjt.is_active, hjt.hourly_rate
        FROM helper_job_types hjt
        JOIN job_categories jc ON hjt.job_category_id = jc.id
        WHERE hjt.helper_id = test_helper_id
        ORDER BY hjt.is_active DESC, jc.name
    LOOP
        RAISE NOTICE '  - % | Active: % | Rate: LKR %', 
                     cat_record.name, 
                     cat_record.is_active, 
                     cat_record.hourly_rate;
    END LOOP;
    
    -- Count active categories
    SELECT COUNT(*) INTO active_categories_count
    FROM helper_job_types hjt
    WHERE hjt.helper_id = test_helper_id AND hjt.is_active = true;
    
    RAISE NOTICE '';
    RAISE NOTICE 'Active Categories: %', active_categories_count;
    
    -- Show available jobs (before filtering)
    RAISE NOTICE '';
    RAISE NOTICE 'All Available Public Jobs:';
    FOR job_record IN 
        SELECT j.title, j.job_category_name, j.category_id
        FROM jobs j
        WHERE j.is_private = false 
          AND j.status = 'pending' 
          AND j.assigned_helper_id IS NULL
        ORDER BY j.created_at DESC
        LIMIT 5
    LOOP
        RAISE NOTICE '  - "%": % (ID: %)', 
                     job_record.title,
                     job_record.job_category_name,
                     job_record.category_id;
    END LOOP;
    
    -- Test the filtering function
    SELECT COUNT(*) INTO jobs_visible_count
    FROM get_public_jobs_for_helper(test_helper_id);
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ FILTERING RESULT:';
    RAISE NOTICE 'Helper should see: % jobs (only for active categories)', jobs_visible_count;
    
    -- Show which jobs the helper will see
    RAISE NOTICE '';
    RAISE NOTICE 'Jobs Helper Will See:';
    FOR job_record IN 
        SELECT title, job_category_name
        FROM get_public_jobs_for_helper(test_helper_id)
        LIMIT 5
    LOOP
        RAISE NOTICE '  ✓ "%": %', job_record.title, job_record.job_category_name;
    END LOOP;
    
    IF jobs_visible_count = 0 AND active_categories_count > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '⚠️  Helper has active categories but sees no jobs - check if job categories match';
    ELSIF jobs_visible_count > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '✅ FILTERING WORKING CORRECTLY!';
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE 'ℹ️  Helper has no active categories selected';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉 HELPER JOB FILTERING FIX COMPLETED!';
    RAISE NOTICE '';
END $$; 