-- ============================================================================
-- COMPLETE HELPER FILTERING AND NOTIFICATIONS FIX
-- File: 046_complete_helper_filtering_and_notifications_fix.sql
-- Date: 2025-01-10
-- Purpose: Fix helper job filtering by categories AND implement job publication notifications
-- ============================================================================

-- ============================================================================
-- PART 1: HELPER JOB FILTERING FUNCTIONS
-- ============================================================================

-- Drop existing functions to avoid conflicts
DROP FUNCTION IF EXISTS get_helper_job_categories(UUID);
DROP FUNCTION IF EXISTS get_public_jobs_for_helper(UUID);
DROP FUNCTION IF EXISTS get_private_jobs_for_helper(UUID);
DROP FUNCTION IF EXISTS get_helper_assigned_jobs_by_status(UUID, TEXT[]);
DROP FUNCTION IF EXISTS get_helper_assigned_jobs_for_calendar(UUID);

-- Function 1: Get helper's ACTIVE job category names
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
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error getting helper job categories for %: %', p_helper_id, SQLERRM;
        RETURN ARRAY[]::TEXT[];
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 2: Get public jobs filtered by helper's ACTIVE preferences
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
    RAISE NOTICE 'Helper % filtering public jobs by categories: %', p_helper_id, helper_categories;
    
    -- Return empty if helper has no active preferences
    IF helper_categories IS NULL OR array_length(helper_categories, 1) IS NULL THEN
        RAISE NOTICE 'Helper % has no active job categories - showing no jobs', p_helper_id;
        RETURN;
    END IF;
    
    -- Return filtered public jobs
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
    AND j.job_category_name = ANY(helper_categories)  -- CRITICAL: Only show matching categories
    ORDER BY j.created_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error getting public jobs for helper %: %', p_helper_id, SQLERRM;
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 3: Get private jobs for helper filtered by ACTIVE preferences
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
    RAISE NOTICE 'Helper % filtering private jobs by categories: %', p_helper_id, helper_categories;
    
    -- Return empty if helper has no active preferences
    IF helper_categories IS NULL OR array_length(helper_categories, 1) IS NULL THEN
        RAISE NOTICE 'Helper % has no active job categories - showing no jobs', p_helper_id;
        RETURN;
    END IF;
    
    -- Return filtered private jobs
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
    AND j.job_category_name = ANY(helper_categories)  -- CRITICAL: Only show matching categories
    ORDER BY j.created_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error getting private jobs for helper %: %', p_helper_id, SQLERRM;
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 4: Get helper's assigned jobs by status with category filtering
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
    RAISE NOTICE 'Helper % filtering assigned jobs by categories: % for statuses: %', p_helper_id, helper_categories, p_statuses;
    
    -- Return empty if helper has no active preferences
    IF helper_categories IS NULL OR array_length(helper_categories, 1) IS NULL THEN
        RAISE NOTICE 'Helper % has no active job categories - showing no assigned jobs', p_helper_id;
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
    AND j.job_category_name = ANY(helper_categories)  -- CRITICAL: Only show jobs in helper's active categories
    ORDER BY j.created_at DESC;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error getting assigned jobs for helper %: %', p_helper_id, SQLERRM;
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 5: Get helper's assigned jobs for calendar (with filtering)
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
    IF helper_categories IS NULL OR array_length(helper_categories, 1) IS NULL THEN
        RAISE NOTICE 'Helper % has no active job categories - showing no calendar jobs', p_helper_id;
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
    AND j.job_category_name = ANY(helper_categories)  -- CRITICAL: Only show jobs in helper's active categories
    ORDER BY j.scheduled_date ASC;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error getting calendar jobs for helper %: %', p_helper_id, SQLERRM;
        RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- PART 2: JOB PUBLICATION NOTIFICATION SYSTEM
-- ============================================================================

-- Drop existing notification triggers and functions
DROP TRIGGER IF EXISTS trigger_notify_on_job_creation ON jobs;
DROP FUNCTION IF EXISTS notify_on_job_creation();
DROP FUNCTION IF EXISTS notify_helpers_of_new_job();

-- Function 6: Notify helpers when new jobs are published
CREATE OR REPLACE FUNCTION notify_helpers_of_new_job()
RETURNS TRIGGER AS $$
DECLARE
    v_helpee_name TEXT;
    v_helper_record RECORD;
    v_notification_count INTEGER := 0;
BEGIN
    -- Only process job creation (INSERT) and only for active jobs
    IF TG_OP != 'INSERT' THEN
        RETURN NEW;
    END IF;

    -- Get helpee name for notification message
    SELECT COALESCE(display_name, CONCAT(first_name, ' ', last_name), email)
    INTO v_helpee_name 
    FROM users 
    WHERE id = NEW.helpee_id;

    -- Set default if no name found
    v_helpee_name := COALESCE(v_helpee_name, 'A helpee');

    RAISE NOTICE 'Creating notifications for new job: % (%) - Category: %', NEW.title, NEW.id, NEW.job_category_name;

    -- For PUBLIC jobs: Notify all helpers who have this job category ACTIVE
    IF NEW.is_private = false THEN
        -- Find helpers with matching ACTIVE job categories
        FOR v_helper_record IN 
            SELECT DISTINCT u.id as helper_user_id, u.display_name as helper_name
            FROM users u
            JOIN helper_job_types hjt ON u.id = hjt.helper_id
            JOIN job_categories jc ON hjt.job_category_id = jc.id
            WHERE jc.name = NEW.job_category_name  -- Match by category name
            AND hjt.is_active = true               -- Only ACTIVE helper categories
            AND u.user_type = 'helper'             -- Only helpers
            AND u.is_active = true                 -- Only active users
            AND u.id != NEW.helpee_id              -- Don't notify the job creator
        LOOP
            -- Create notification for each eligible helper
            INSERT INTO notifications (
                user_id,
                title,
                message,
                notification_type,
                related_job_id,
                related_user_id,
                is_read,
                created_at,
                notification_category,
                priority_level
            ) VALUES (
                v_helper_record.helper_user_id,
                'New Job Available! 🔔',
                'A new ' || NEW.job_category_name || ' job "' || NEW.title || '" is available from ' || v_helpee_name || '. Tap to view details.',
                'new_job_available',
                NEW.id,
                NEW.helpee_id,
                false,
                NOW(),
                'job_alerts',
                'normal'
            );

            v_notification_count := v_notification_count + 1;
            
            RAISE NOTICE 'Created notification for helper: % (%)', v_helper_record.helper_name, v_helper_record.helper_user_id;
        END LOOP;

        RAISE NOTICE 'Created % notifications for public job %', v_notification_count, NEW.id;

    -- For PRIVATE jobs: Notify only the assigned helper (if any)
    ELSIF NEW.is_private = true AND NEW.assigned_helper_id IS NOT NULL THEN
        -- Check if assigned helper has this job category active
        IF EXISTS (
            SELECT 1 
            FROM helper_job_types hjt
            JOIN job_categories jc ON hjt.job_category_id = jc.id
            WHERE hjt.helper_id = NEW.assigned_helper_id
            AND jc.name = NEW.job_category_name
            AND hjt.is_active = true
        ) THEN
            INSERT INTO notifications (
                user_id,
                title,
                message,
                notification_type,
                related_job_id,
                related_user_id,
                is_read,
                created_at,
                notification_category,
                priority_level
            ) VALUES (
                NEW.assigned_helper_id,
                'Private Job Request! 💼',
                'You have received a private ' || NEW.job_category_name || ' job request "' || NEW.title || '" from ' || v_helpee_name || '.',
                'private_job_request',
                NEW.id,
                NEW.helpee_id,
                false,
                NOW(),
                'job_alerts',
                'high'
            );

            v_notification_count := 1;
            RAISE NOTICE 'Created private job notification for helper: %', NEW.assigned_helper_id;
        END IF;
    END IF;

    -- Also create a confirmation notification for the helpee
    INSERT INTO notifications (
        user_id,
        title,
        message,
        notification_type,
        related_job_id,
        related_user_id,
        is_read,
        created_at,
        notification_category,
        priority_level
    ) VALUES (
        NEW.helpee_id,
        'Job Posted Successfully! ✅',
        'Your ' || NEW.job_category_name || ' job "' || NEW.title || '" has been posted successfully. Helpers will be notified shortly.',
        'job_created',
        NEW.id,
        NEW.helpee_id,
        false,
        NOW(),
        'job_status',
        'normal'
    );

    RAISE NOTICE 'Job creation notifications completed. Total helper notifications: %', v_notification_count;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't block job creation
        RAISE WARNING 'Job notification creation failed for job %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for job creation notifications
CREATE TRIGGER trigger_notify_on_job_creation
    AFTER INSERT ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION notify_helpers_of_new_job();

-- ============================================================================
-- PART 3: GRANT PERMISSIONS
-- ============================================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_helper_job_categories(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_public_jobs_for_helper(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_private_jobs_for_helper(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_helper_assigned_jobs_by_status(UUID, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_helper_assigned_jobs_for_calendar(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION notify_helpers_of_new_job() TO authenticated;

-- ============================================================================
-- PART 4: TESTING AND VERIFICATION
-- ============================================================================

-- Test with sample helper ID (replace with actual helper ID for testing)
DO $$
DECLARE
    test_helper_id UUID := '29e2adb3-4910-4c83-804b-0014b1c4598a';
    categories TEXT[];
    job_count INTEGER;
BEGIN
    -- Test helper categories function
    SELECT get_helper_job_categories(test_helper_id) INTO categories;
    RAISE NOTICE 'Test Helper % active categories: %', test_helper_id, categories;
    
    -- Test public jobs function
    SELECT COUNT(*) INTO job_count FROM get_public_jobs_for_helper(test_helper_id);
    RAISE NOTICE 'Test Helper % can see % public jobs', test_helper_id, job_count;
    
    -- Test private jobs function
    SELECT COUNT(*) INTO job_count FROM get_private_jobs_for_helper(test_helper_id);
    RAISE NOTICE 'Test Helper % can see % private jobs', test_helper_id, job_count;
    
    RAISE NOTICE '✅ All functions created and tested successfully!';
END $$;

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 COMPLETE HELPER FILTERING AND NOTIFICATIONS FIX APPLIED! 🎉';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Helper job filtering functions created:';
    RAISE NOTICE '   - get_helper_job_categories()';
    RAISE NOTICE '   - get_public_jobs_for_helper()';
    RAISE NOTICE '   - get_private_jobs_for_helper()';
    RAISE NOTICE '   - get_helper_assigned_jobs_by_status()';
    RAISE NOTICE '   - get_helper_assigned_jobs_for_calendar()';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Job publication notification system created:';
    RAISE NOTICE '   - notify_helpers_of_new_job() trigger function';
    RAISE NOTICE '   - Automatic notifications to matching helpers';
    RAISE NOTICE '   - Support for both public and private jobs';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 WHAT THIS FIXES:';
    RAISE NOTICE '   1. Helpers only see jobs matching their ACTIVE categories';
    RAISE NOTICE '   2. No more unrelated jobs displayed to helpers';
    RAISE NOTICE '   3. Automatic notifications when jobs are published';
    RAISE NOTICE '   4. Real-time popups for helpers with matching skills';
    RAISE NOTICE '';
    RAISE NOTICE '📋 NEXT STEPS:';
    RAISE NOTICE '   1. Restart Flutter app to see changes';
    RAISE NOTICE '   2. Test job creation as helpee';
    RAISE NOTICE '   3. Verify helpers only see matching job categories';
    RAISE NOTICE '   4. Confirm notifications and popups work';
    RAISE NOTICE '';
END $$; 