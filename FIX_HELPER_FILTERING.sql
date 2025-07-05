-- ============================================================================
-- FIX HELPER FILTERING - CORRECTED VERSION
-- ============================================================================
-- This fixes the helper job filtering to use is_active = true from helper_job_types

-- Drop existing functions to avoid conflicts
DROP FUNCTION IF EXISTS get_helper_job_categories(UUID);
DROP FUNCTION IF EXISTS get_public_jobs_for_helper(UUID);
DROP FUNCTION IF EXISTS get_private_jobs_for_helper(UUID);

-- Function to get helper's ACTIVE job category names
CREATE OR REPLACE FUNCTION get_helper_job_categories(p_helper_id UUID)
RETURNS TEXT[] AS $$
DECLARE
    category_names TEXT[];
BEGIN
    SELECT ARRAY_AGG(jc.name)
    INTO category_names
    FROM helper_job_types hjt
    JOIN job_categories jc ON hjt.job_category_id = jc.id
    WHERE hjt.helper_id = p_helper_id
    AND hjt.is_active = true;  -- Only get ACTIVE categories
    
    RETURN COALESCE(category_names, ARRAY[]::TEXT[]);
END;
$$ LANGUAGE plpgsql;

-- Function to get public jobs filtered by helper's ACTIVE preferences
CREATE OR REPLACE FUNCTION get_public_jobs_for_helper(p_helper_id UUID)
RETURNS TABLE (
    id UUID,
    title VARCHAR(200),
    description TEXT,
    job_category_name VARCHAR(100),
    hourly_rate DECIMAL(10, 2),
    scheduled_date DATE,
    scheduled_start_time TIME,
    location_address TEXT,
    status VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE,
    helpee_first_name VARCHAR(100),
    helpee_last_name VARCHAR(100),
    helpee_location_city VARCHAR(100)
) AS $$
DECLARE
    helper_categories TEXT[];
BEGIN
    -- Get helper's ACTIVE job categories
    SELECT get_helper_job_categories(p_helper_id) INTO helper_categories;
    
    -- Debug output
    RAISE NOTICE 'Helper % has active categories: %', p_helper_id, helper_categories;
    
    -- Return empty if helper has no active preferences
    IF array_length(helper_categories, 1) IS NULL THEN
        RAISE NOTICE 'Helper % has no active job categories', p_helper_id;
        RETURN;
    END IF;
    
    -- Return filtered public jobs
    RETURN QUERY
    SELECT 
        j.id,
        j.title,
        j.description,
        j.job_category_name,
        j.hourly_rate,
        j.scheduled_date,
        j.scheduled_start_time,
        j.location_address,
        j.status,
        j.created_at,
        u.first_name,
        u.last_name,
        u.location_city
    FROM jobs j
    JOIN users u ON j.helpee_id = u.id
    WHERE j.is_private = false
    AND j.status = 'pending'
    AND j.assigned_helper_id IS NULL
    AND j.job_category_name = ANY(helper_categories)
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get private jobs for helper filtered by ACTIVE preferences
CREATE OR REPLACE FUNCTION get_private_jobs_for_helper(p_helper_id UUID)
RETURNS TABLE (
    id UUID,
    title VARCHAR(200),
    description TEXT,
    job_category_name VARCHAR(100),
    hourly_rate DECIMAL(10, 2),
    scheduled_date DATE,
    scheduled_start_time TIME,
    location_address TEXT,
    status VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE,
    helpee_first_name VARCHAR(100),
    helpee_last_name VARCHAR(100),
    helpee_location_city VARCHAR(100)
) AS $$
DECLARE
    helper_categories TEXT[];
BEGIN
    -- Get helper's ACTIVE job categories
    SELECT get_helper_job_categories(p_helper_id) INTO helper_categories;
    
    -- Debug output
    RAISE NOTICE 'Helper % has active categories: %', p_helper_id, helper_categories;
    
    -- Return empty if helper has no active preferences
    IF array_length(helper_categories, 1) IS NULL THEN
        RAISE NOTICE 'Helper % has no active job categories', p_helper_id;
        RETURN;
    END IF;
    
    -- Return filtered private jobs
    RETURN QUERY
    SELECT 
        j.id,
        j.title,
        j.description,
        j.job_category_name,
        j.hourly_rate,
        j.scheduled_date,
        j.scheduled_start_time,
        j.location_address,
        j.status,
        j.created_at,
        u.first_name,
        u.last_name,
        u.location_city
    FROM jobs j
    JOIN users u ON j.helpee_id = u.id
    WHERE j.is_private = true
    AND j.assigned_helper_id = p_helper_id
    AND j.status = 'pending'
    AND j.job_category_name = ANY(helper_categories)
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Test the functions
DO $$
DECLARE
    test_helper_id UUID := '29e2adb3-4910-4c83-804b-0014b1c4598a';
    categories TEXT[];
    job_count INTEGER;
BEGIN
    -- Test get_helper_job_categories
    SELECT get_helper_job_categories(test_helper_id) INTO categories;
    RAISE NOTICE 'TEST: Helper % active categories: %', test_helper_id, categories;
    
    -- Test get_public_jobs_for_helper
    SELECT COUNT(*) INTO job_count FROM get_public_jobs_for_helper(test_helper_id);
    RAISE NOTICE 'TEST: Helper % has % matching public jobs', test_helper_id, job_count;
    
    -- Show what categories are active in the database
    RAISE NOTICE 'DEBUG: Helper job types in database:';
    FOR categories IN 
        SELECT ARRAY[jc.name, hjt.is_active::text] 
        FROM helper_job_types hjt
        JOIN job_categories jc ON hjt.job_category_id = jc.id
        WHERE hjt.helper_id = test_helper_id
        ORDER BY jc.name
    LOOP
        RAISE NOTICE '  Category: %, Active: %', categories[1], categories[2];
    END LOOP;
    
END $$;

-- Verify the functions were created successfully
SELECT 
    'Helper Filtering Fix Applied' as status,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN ('get_helper_job_categories', 'get_public_jobs_for_helper', 'get_private_jobs_for_helper')
ORDER BY routine_name; 