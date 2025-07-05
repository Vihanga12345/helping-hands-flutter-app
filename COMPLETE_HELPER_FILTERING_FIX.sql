-- ============================================================================
-- COMPLETE HELPER FILTERING FIX
-- ============================================================================
-- This applies job category filtering to ALL helper pages: Activity (Pending/Ongoing/Completed) and Calendar

-- Drop existing functions
DROP FUNCTION IF EXISTS get_helper_job_categories(UUID);
DROP FUNCTION IF EXISTS get_public_jobs_for_helper(UUID);
DROP FUNCTION IF EXISTS get_private_jobs_for_helper(UUID);
DROP FUNCTION IF EXISTS get_helper_assigned_jobs_by_status(UUID, TEXT[]);

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
    AND hjt.is_active = true;
    
    RETURN COALESCE(category_names, ARRAY[]::TEXT[]);
END;
$$ LANGUAGE plpgsql;

-- Function to get public jobs filtered by helper's preferences
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
    SELECT get_helper_job_categories(p_helper_id) INTO helper_categories;
    
    IF array_length(helper_categories, 1) IS NULL THEN
        RETURN;
    END IF;
    
    RETURN QUERY
    SELECT 
        j.id, j.title, j.description, j.job_category_name, j.hourly_rate,
        j.scheduled_date, j.scheduled_start_time, j.location_address,
        j.status, j.created_at, u.first_name, u.last_name, u.location_city
    FROM jobs j
    JOIN users u ON j.helpee_id = u.id
    WHERE j.is_private = false
    AND j.status = 'pending'
    AND j.assigned_helper_id IS NULL
    AND j.job_category_name = ANY(helper_categories)
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get private jobs for helper
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
    SELECT get_helper_job_categories(p_helper_id) INTO helper_categories;
    
    IF array_length(helper_categories, 1) IS NULL THEN
        RETURN;
    END IF;
    
    RETURN QUERY
    SELECT 
        j.id, j.title, j.description, j.job_category_name, j.hourly_rate,
        j.scheduled_date, j.scheduled_start_time, j.location_address,
        j.status, j.created_at, u.first_name, u.last_name, u.location_city
    FROM jobs j
    JOIN users u ON j.helpee_id = u.id
    WHERE j.is_private = true
    AND j.assigned_helper_id = p_helper_id
    AND j.status = 'pending'
    AND j.job_category_name = ANY(helper_categories)
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- NEW FUNCTION: Get helper's assigned jobs by status with job category filtering
CREATE OR REPLACE FUNCTION get_helper_assigned_jobs_by_status(p_helper_id UUID, p_statuses TEXT[])
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
    timer_status VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE,
    helpee_first_name VARCHAR(100),
    helpee_last_name VARCHAR(100),
    helpee_location_city VARCHAR(100)
) AS $$
DECLARE
    helper_categories TEXT[];
BEGIN
    -- Get helper's active job categories
    SELECT get_helper_job_categories(p_helper_id) INTO helper_categories;
    
    -- Debug output
    RAISE NOTICE 'Helper % filtering assigned jobs by categories: %', p_helper_id, helper_categories;
    RAISE NOTICE 'Looking for statuses: %', p_statuses;
    
    -- Return empty if helper has no active preferences
    IF array_length(helper_categories, 1) IS NULL THEN
        RAISE NOTICE 'Helper % has no active job categories', p_helper_id;
        RETURN;
    END IF;
    
    -- Return filtered assigned jobs
    RETURN QUERY
    SELECT 
        j.id, j.title, j.description, j.job_category_name, j.hourly_rate,
        j.scheduled_date, j.scheduled_start_time, j.location_address,
        j.status, j.timer_status, j.created_at, u.first_name, u.last_name, u.location_city
    FROM jobs j
    JOIN users u ON j.helpee_id = u.id
    WHERE j.assigned_helper_id = p_helper_id
    AND j.status = ANY(p_statuses)
    AND j.job_category_name = ANY(helper_categories)  -- Only show jobs in helper's active categories
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- NEW FUNCTION: Get helper's assigned jobs for calendar (with filtering)
CREATE OR REPLACE FUNCTION get_helper_assigned_jobs_for_calendar(p_helper_id UUID)
RETURNS TABLE (
    id UUID,
    title VARCHAR(200),
    scheduled_date DATE,
    scheduled_start_time TIME,
    status VARCHAR(50),
    is_private BOOLEAN,
    helpee_first_name VARCHAR(100),
    helpee_last_name VARCHAR(100)
) AS $$
DECLARE
    helper_categories TEXT[];
BEGIN
    -- Get helper's active job categories
    SELECT get_helper_job_categories(p_helper_id) INTO helper_categories;
    
    -- Return empty if helper has no active preferences
    IF array_length(helper_categories, 1) IS NULL THEN
        RETURN;
    END IF;
    
    -- Return filtered assigned jobs for calendar
    RETURN QUERY
    SELECT 
        j.id, j.title, j.scheduled_date, j.scheduled_start_time,
        j.status, j.is_private, u.first_name, u.last_name
    FROM jobs j
    JOIN users u ON j.helpee_id = u.id
    WHERE j.assigned_helper_id = p_helper_id
    AND j.scheduled_date IS NOT NULL
    AND j.job_category_name = ANY(helper_categories)  -- Only show jobs in helper's active categories
    ORDER BY j.scheduled_date ASC;
END;
$$ LANGUAGE plpgsql;

-- Test the functions with your helper ID
DO $$
DECLARE
    test_helper_id UUID := '29e2adb3-4910-4c83-804b-0014b1c4598a';
    categories TEXT[];
    job_count INTEGER;
BEGIN
    -- Test categories
    SELECT get_helper_job_categories(test_helper_id) INTO categories;
    RAISE NOTICE 'TEST: Helper % active categories: %', test_helper_id, categories;
    
    -- Test ongoing jobs
    SELECT COUNT(*) INTO job_count 
    FROM get_helper_assigned_jobs_by_status(test_helper_id, ARRAY['ongoing', 'accepted', 'started']);
    RAISE NOTICE 'TEST: Helper % has % ongoing jobs', test_helper_id, job_count;
    
    -- Test completed jobs
    SELECT COUNT(*) INTO job_count 
    FROM get_helper_assigned_jobs_by_status(test_helper_id, ARRAY['completed']);
    RAISE NOTICE 'TEST: Helper % has % completed jobs', test_helper_id, job_count;
    
    -- Test calendar jobs
    SELECT COUNT(*) INTO job_count 
    FROM get_helper_assigned_jobs_for_calendar(test_helper_id);
    RAISE NOTICE 'TEST: Helper % has % calendar jobs', test_helper_id, job_count;
    
    -- Show database debug info
    RAISE NOTICE '=== DATABASE DEBUG INFO ===';
    RAISE NOTICE 'All job categories in helper_job_types for helper %:', test_helper_id;
    
    FOR categories IN 
        SELECT ARRAY[jc.name, hjt.is_active::text] 
        FROM helper_job_types hjt
        JOIN job_categories jc ON hjt.job_category_id = jc.id
        WHERE hjt.helper_id = test_helper_id
        ORDER BY jc.name
    LOOP
        RAISE NOTICE '  Category: %, Active: %', categories[1], categories[2];
    END LOOP;
    
    RAISE NOTICE 'All jobs assigned to helper % (regardless of category):', test_helper_id;
    FOR categories IN 
        SELECT ARRAY[j.title, j.status, j.job_category_name] 
        FROM jobs j
        WHERE j.assigned_helper_id = test_helper_id
        ORDER BY j.created_at DESC
    LOOP
        RAISE NOTICE '  Job: %, Status: %, Category: %', categories[1], categories[2], categories[3];
    END LOOP;
    
END $$;

-- Verify functions exist
SELECT 'Complete Helper Filtering Fix Applied' as status; 