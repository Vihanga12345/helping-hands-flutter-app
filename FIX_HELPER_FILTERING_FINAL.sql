-- ============================================================================
-- CRITICAL HELPER JOB FILTERING FIX
-- ============================================================================
-- This fixes the bug where helpers see jobs for categories they haven't selected

DROP FUNCTION IF EXISTS get_public_jobs_for_helper(UUID);

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

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_public_jobs_for_helper(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_private_jobs_for_helper(UUID) TO authenticated; 