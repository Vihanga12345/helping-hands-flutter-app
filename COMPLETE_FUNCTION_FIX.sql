-- ============================================================================
-- COMPLETE FUNCTION FIX
-- ============================================================================
-- This creates ALL missing database functions for helper job filtering

-- 1. Helper categories function
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

-- 2. Public jobs function
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

-- 3. Private jobs function
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

-- 4. Assigned jobs function
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
    SELECT get_helper_job_categories(p_helper_id) INTO helper_categories;
    
    -- If no active categories, return all assigned jobs (fallback)
    IF array_length(helper_categories, 1) IS NULL THEN
        RETURN QUERY
        SELECT 
            j.id, j.title, j.description, j.job_category_name, j.hourly_rate,
            j.scheduled_date, j.scheduled_start_time, j.location_address,
            j.status, j.timer_status, j.created_at, 
            u.first_name, u.last_name, u.location_city
        FROM jobs j
        JOIN users u ON j.helpee_id = u.id
        WHERE j.assigned_helper_id = p_helper_id
        AND j.status = ANY(p_statuses)
        ORDER BY j.created_at DESC;
        RETURN;
    END IF;
    
    -- Return filtered jobs by active categories
    RETURN QUERY
    SELECT 
        j.id, j.title, j.description, j.job_category_name, j.hourly_rate,
        j.scheduled_date, j.scheduled_start_time, j.location_address,
        j.status, j.timer_status, j.created_at,
        u.first_name, u.last_name, u.location_city
    FROM jobs j
    JOIN users u ON j.helpee_id = u.id
    WHERE j.assigned_helper_id = p_helper_id
    AND j.status = ANY(p_statuses)
    AND j.job_category_name = ANY(helper_categories)
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 5. Calendar jobs function
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
    SELECT get_helper_job_categories(p_helper_id) INTO helper_categories;
    
    -- If no active categories, return all assigned jobs (fallback)
    IF array_length(helper_categories, 1) IS NULL THEN
        RETURN QUERY
        SELECT 
            j.id, j.title, j.scheduled_date, j.scheduled_start_time,
            j.status, j.is_private, u.first_name, u.last_name
        FROM jobs j
        JOIN users u ON j.helpee_id = u.id
        WHERE j.assigned_helper_id = p_helper_id
        AND j.scheduled_date IS NOT NULL
        ORDER BY j.scheduled_date ASC;
        RETURN;
    END IF;
    
    -- Return filtered jobs by active categories
    RETURN QUERY
    SELECT 
        j.id, j.title, j.scheduled_date, j.scheduled_start_time,
        j.status, j.is_private, u.first_name, u.last_name
    FROM jobs j
    JOIN users u ON j.helpee_id = u.id
    WHERE j.assigned_helper_id = p_helper_id
    AND j.scheduled_date IS NOT NULL
    AND j.job_category_name = ANY(helper_categories)
    ORDER BY j.scheduled_date ASC;
END;
$$ LANGUAGE plpgsql;

-- 6. Grant permissions
GRANT EXECUTE ON FUNCTION get_helper_job_categories(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_public_jobs_for_helper(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_private_jobs_for_helper(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_helper_assigned_jobs_by_status(UUID, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_helper_assigned_jobs_for_calendar(UUID) TO authenticated;

-- 7. Test with your helper ID
DO $$
DECLARE
    test_helper_id UUID := '29e2adb3-4910-4c83-804b-0014b1c4598a';
    categories TEXT[];
    job_count INTEGER;
BEGIN
    -- Test helper categories
    SELECT get_helper_job_categories(test_helper_id) INTO categories;
    RAISE NOTICE 'Helper % has ACTIVE categories: %', test_helper_id, categories;
    
    -- Test public jobs
    SELECT COUNT(*) INTO job_count FROM get_public_jobs_for_helper(test_helper_id);
    RAISE NOTICE 'Helper % has % available public jobs', test_helper_id, job_count;
    
    -- Test ongoing jobs
    SELECT COUNT(*) INTO job_count 
    FROM get_helper_assigned_jobs_by_status(test_helper_id, ARRAY['ongoing', 'accepted', 'started']);
    RAISE NOTICE 'Helper % has % ongoing jobs', test_helper_id, job_count;
    
    -- Test completed jobs
    SELECT COUNT(*) INTO job_count 
    FROM get_helper_assigned_jobs_by_status(test_helper_id, ARRAY['completed']);
    RAISE NOTICE 'Helper % has % completed jobs', test_helper_id, job_count;
    
    -- Show all categories with their status
    RAISE NOTICE '=== HELPER JOB TYPES DEBUG ===';
    FOR categories IN 
        SELECT ARRAY[jc.name, hjt.is_active::text] 
        FROM helper_job_types hjt
        JOIN job_categories jc ON hjt.job_category_id = jc.id
        WHERE hjt.helper_id = test_helper_id
        ORDER BY jc.name
    LOOP
        RAISE NOTICE 'Category: %, Active: %', categories[1], categories[2];
    END LOOP;
    
    -- Show all jobs with categories
    RAISE NOTICE '=== ALL JOBS IN DATABASE ===';
    FOR categories IN 
        SELECT ARRAY[j.title, j.job_category_name, j.status] 
        FROM jobs j
        ORDER BY j.created_at DESC
        LIMIT 10
    LOOP
        RAISE NOTICE 'Job: %, Category: %, Status: %', categories[1], categories[2], categories[3];
    END LOOP;
    
END $$;

-- 8. Verify all functions exist
SELECT 'All Functions Created Successfully' as status, routine_name
FROM information_schema.routines 
WHERE routine_name IN (
    'get_helper_job_categories', 
    'get_public_jobs_for_helper',
    'get_private_jobs_for_helper',
    'get_helper_assigned_jobs_by_status',
    'get_helper_assigned_jobs_for_calendar'
)
ORDER BY routine_name; 