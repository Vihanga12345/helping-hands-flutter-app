-- ============================================================================
-- HELPER RESTRICTION FEATURE: Update job filtering functions
-- ============================================================================
-- This migration updates existing database functions to respect the jobs_visible
-- column when filtering jobs for helpers.
-- ============================================================================

-- Update get_public_jobs_for_helper function to include jobs_visible check
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
    helper_jobs_visible BOOLEAN;
    FOUND INTEGER;
BEGIN
    -- Check if helper has jobs_visible enabled
    SELECT users.jobs_visible INTO helper_jobs_visible
    FROM users
    WHERE users.id = p_helper_id AND users.user_type = 'helper';
    
    -- If helper doesn't exist or jobs are not visible, return empty result
    IF helper_jobs_visible IS NULL OR helper_jobs_visible = false THEN
        RAISE NOTICE 'Helper % either does not exist or has jobs_visible disabled', p_helper_id;
        RETURN;
    END IF;

    -- Debug: Show helper's active categories
    RAISE NOTICE 'Getting public jobs for helper: % (jobs_visible: %)', p_helper_id, helper_jobs_visible;
    RAISE NOTICE 'Helper active categories: %', (
        SELECT STRING_AGG(jc.name, ', ')
        FROM helper_job_types hjt
        JOIN job_categories jc ON hjt.job_category_id = jc.id
        WHERE hjt.helper_id = p_helper_id AND hjt.is_active = true
    );

    -- Return ONLY jobs that match helper's ACTIVE categories AND jobs_visible is true
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
    RAISE NOTICE 'Returned % public jobs for helper %', FOUND, p_helper_id;
    
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- Update get_private_jobs_for_helper function (if it exists)
-- ============================================================================

-- Check if the function exists first
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_private_jobs_for_helper') THEN
        -- Update private job function to respect jobs_visible
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
        ) AS $func$
        DECLARE
            helper_jobs_visible BOOLEAN;
        BEGIN
            -- Check if helper has jobs_visible enabled
            SELECT users.jobs_visible INTO helper_jobs_visible
            FROM users
            WHERE users.id = p_helper_id AND users.user_type = 'helper';
            
            -- If helper doesn't exist or jobs are not visible, return empty result
            IF helper_jobs_visible IS NULL OR helper_jobs_visible = false THEN
                RAISE NOTICE 'Helper % either does not exist or has jobs_visible disabled for private jobs', p_helper_id;
                RETURN;
            END IF;

            -- Return private job invitations
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
              AND j.status = 'pending'
              AND j.assigned_helper_id = p_helper_id  -- Specifically assigned to this helper
            ORDER BY j.created_at DESC;
            
        END;
        $func$ LANGUAGE plpgsql SECURITY DEFINER;
        
        RAISE NOTICE 'Updated get_private_jobs_for_helper function with jobs_visible check';
    END IF;
END
$$;

-- ============================================================================
-- Grant permissions
-- ============================================================================
GRANT EXECUTE ON FUNCTION get_public_jobs_for_helper(UUID) TO authenticated;

-- Grant permission for private job function if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_private_jobs_for_helper') THEN
        GRANT EXECUTE ON FUNCTION get_private_jobs_for_helper(UUID) TO authenticated;
    END IF;
END
$$;

-- ============================================================================
-- Verification and Testing
-- ============================================================================
-- Test query to verify the function works:
-- SELECT * FROM get_public_jobs_for_helper('your-helper-id-here');

-- Query to check helper's jobs_visible status:
-- SELECT id, first_name, last_name, user_type, jobs_visible 
-- FROM users 
-- WHERE user_type = 'helper' 
-- ORDER BY first_name; 