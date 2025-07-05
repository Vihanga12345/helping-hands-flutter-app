-- ============================================================================
-- FIX FUNCTION RETURN TYPES
-- ============================================================================
-- Run this to fix the timestamp type mismatch in helper filtering functions

-- Drop and recreate the functions with correct return types
DROP FUNCTION IF EXISTS get_public_jobs_for_helper(UUID);
DROP FUNCTION IF EXISTS get_private_jobs_for_helper(UUID);

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
    -- Get helper's preferred job categories
    SELECT get_helper_job_categories(p_helper_id) INTO helper_categories;
    
    -- Return empty if helper has no preferences
    IF array_length(helper_categories, 1) IS NULL THEN
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
    -- Get helper's preferred job categories
    SELECT get_helper_job_categories(p_helper_id) INTO helper_categories;
    
    -- Return empty if helper has no preferences
    IF array_length(helper_categories, 1) IS NULL THEN
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

-- Verify the functions were created successfully
SELECT 
    'Function Fix Applied' as status,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN ('get_public_jobs_for_helper', 'get_private_jobs_for_helper')
ORDER BY routine_name; 