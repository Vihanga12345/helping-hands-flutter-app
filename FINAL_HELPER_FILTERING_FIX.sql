-- ====================================================================================
-- FINAL HELPER JOB FILTERING FIX - DEFINITIVE SOLUTION
-- ====================================================================================
-- This WILL fix the bug where helpers see jobs for categories they haven't selected

-- STEP 1: Drop the broken function completely
DROP FUNCTION IF EXISTS get_public_jobs_for_helper(UUID);
DROP FUNCTION IF EXISTS get_private_jobs_for_helper(UUID);

-- STEP 2: Create the corrected public jobs function
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
BEGIN
    -- CRITICAL: Only return jobs where helper has ACTIVE preference for that category
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
      AND j.helpee_id != p_helper_id
      -- THE CRITICAL FILTER: Only jobs for helper's ACTIVE categories
      AND EXISTS (
          SELECT 1 
          FROM helper_job_types hjt
          JOIN job_categories jc ON hjt.job_category_id = jc.id
          WHERE hjt.helper_id = p_helper_id
            AND hjt.is_active = true  -- MUST be active
            AND (
                jc.id = j.category_id OR 
                jc.name = j.job_category_name
            )
      )
      -- Exclude ignored jobs
      AND NOT EXISTS (
          SELECT 1 FROM job_ignores ji 
          WHERE ji.job_id = j.id AND ji.helper_id = p_helper_id
      )
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- STEP 3: Create the corrected private jobs function  
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
      -- THE CRITICAL FILTER: Only jobs for helper's ACTIVE categories
      AND EXISTS (
          SELECT 1 
          FROM helper_job_types hjt
          JOIN job_categories jc ON hjt.job_category_id = jc.id
          WHERE hjt.helper_id = p_helper_id
            AND hjt.is_active = true  -- MUST be active
            AND (
                jc.id = j.category_id OR 
                jc.name = j.job_category_name
            )
      )
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- STEP 4: Grant permissions
GRANT EXECUTE ON FUNCTION get_public_jobs_for_helper(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_private_jobs_for_helper(UUID) TO authenticated;

-- STEP 5: Test with the actual helper ID from your screenshots
-- This should return ZERO results since helper has "trh" but job is "WORK"
SELECT 
    COUNT(*) as job_count,
    STRING_AGG(job_category_name, ', ') as categories_found
FROM get_public_jobs_for_helper('29e2adb3-4910-4c83-804b-0014b1c4598a'); 