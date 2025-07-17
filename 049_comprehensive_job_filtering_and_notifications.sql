-- ====================================================================================
-- COMPREHENSIVE JOB FILTERING AND NOTIFICATION FIX
-- ====================================================================================
-- This migration ensures:
-- 1. Helpers only see jobs for their selected (active) categories
-- 2. Proper notifications for all job status changes
-- 3. Helpers get notified only for new jobs in their categories

-- Drop existing triggers and functions in correct order
DROP TRIGGER IF EXISTS trigger_notify_on_job_creation ON jobs;
DROP TRIGGER IF EXISTS notify_helpers_of_new_job_trigger ON jobs;
DROP TRIGGER IF EXISTS job_status_notification_trigger ON jobs;

-- Drop functions
DROP FUNCTION IF EXISTS notify_helpers_of_new_job() CASCADE;
DROP FUNCTION IF EXISTS job_status_notification_trigger_func() CASCADE;
DROP FUNCTION IF EXISTS create_job_status_notification(UUID, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS get_public_jobs_for_helper(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_private_jobs_for_helper(UUID) CASCADE;

-- ====================================================================================
-- FUNCTION: Get public jobs filtered by helper's active categories
-- ====================================================================================
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
      AND j.helpee_id != p_helper_id  -- Helper can't see their own job requests
      -- CRITICAL: Only show jobs matching helper's ACTIVE categories
      AND EXISTS (
          SELECT 1 
          FROM helper_job_types hjt
          WHERE hjt.helper_id = p_helper_id
            AND hjt.is_active = true  -- MUST be active
            AND hjt.job_category_id = j.category_id
      )
      -- Exclude ignored jobs
      AND NOT EXISTS (
          SELECT 1 FROM job_ignores ji 
          WHERE ji.job_id = j.id AND ji.helper_id = p_helper_id
      )
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================================
-- FUNCTION: Get private jobs filtered by helper's active categories
-- ====================================================================================
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
      -- CRITICAL: Even private jobs must match helper's active categories
      AND EXISTS (
          SELECT 1 
          FROM helper_job_types hjt
          WHERE hjt.helper_id = p_helper_id
            AND hjt.is_active = true  -- MUST be active
            AND hjt.job_category_id = j.category_id
      )
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================================
-- FUNCTION: Create notifications for job status changes
-- ====================================================================================
CREATE OR REPLACE FUNCTION create_job_status_notification(
    p_job_id UUID,
    p_old_status VARCHAR(20),
    p_new_status VARCHAR(20)
) RETURNS VOID AS $$
DECLARE
    v_job RECORD;
    v_notification_type VARCHAR(50);
    v_title VARCHAR(200);
    v_message TEXT;
    v_target_user_id UUID;
BEGIN
    -- Get job details
    SELECT j.*, 
           h.display_name as helper_name,
           e.display_name as helpee_name
    INTO v_job
    FROM jobs j
    LEFT JOIN users h ON j.assigned_helper_id = h.id
    LEFT JOIN users e ON j.helpee_id = e.id
    WHERE j.id = p_job_id;

    -- Determine notification based on status change
    CASE p_new_status
        WHEN 'accepted' THEN
            v_notification_type := 'job_accepted';
            v_title := 'Job Accepted! ✅';
            v_message := format('Your job "%s" has been accepted by %s', v_job.title, v_job.helper_name);
            v_target_user_id := v_job.helpee_id;
            
        WHEN 'started' THEN
            v_notification_type := 'job_started';
            v_title := 'Job Started! 🚀';
            v_message := format('Work has started on your job "%s"', v_job.title);
            v_target_user_id := v_job.helpee_id;
            
        WHEN 'paused' THEN
            v_notification_type := 'job_paused';
            v_title := 'Job Paused ⏸️';
            v_message := format('Work has been paused on your job "%s"', v_job.title);
            v_target_user_id := v_job.helpee_id;
            
        WHEN 'resumed' THEN
            v_notification_type := 'job_resumed';
            v_title := 'Job Resumed ▶️';
            v_message := format('Work has resumed on your job "%s"', v_job.title);
            v_target_user_id := v_job.helpee_id;
            
        WHEN 'completed' THEN
            -- Create notifications for both parties
            v_notification_type := 'job_completed';
            
            -- Notification for helpee
            INSERT INTO notifications (
                user_id, title, message, notification_type,
                related_job_id, is_read, created_at
            ) VALUES (
                v_job.helpee_id,
                'Job Completed! 🎉',
                format('Your job "%s" has been completed. Please confirm payment.', v_job.title),
                v_notification_type,
                p_job_id,
                false,
                NOW()
            );
            
            -- Notification for helper
            INSERT INTO notifications (
                user_id, title, message, notification_type,
                related_job_id, is_read, created_at
            ) VALUES (
                v_job.assigned_helper_id,
                'Job Completed! 🎉',
                format('You have completed "%s". Awaiting payment confirmation.', v_job.title),
                v_notification_type,
                p_job_id,
                false,
                NOW()
            );
            
            RETURN; -- Exit early since we handled both notifications
            
        ELSE
            RETURN; -- No notification for other statuses
    END CASE;

    -- Create notification (except for completed which is handled above)
    IF v_target_user_id IS NOT NULL AND p_new_status != 'completed' THEN
        INSERT INTO notifications (
            user_id, title, message, notification_type,
            related_job_id, is_read, created_at
        ) VALUES (
            v_target_user_id,
            v_title,
            v_message,
            v_notification_type,
            p_job_id,
            false,
            NOW()
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ====================================================================================
-- TRIGGER: Create notifications on job status change
-- ====================================================================================
CREATE OR REPLACE FUNCTION job_status_notification_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create notification if status actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        PERFORM create_job_status_notification(NEW.id, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER job_status_notification_trigger
    AFTER UPDATE ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION job_status_notification_trigger_func();

-- ====================================================================================
-- FUNCTION: Notify helpers of new job (only matching categories)
-- ====================================================================================
CREATE OR REPLACE FUNCTION notify_helpers_of_new_job()
RETURNS TRIGGER AS $$
DECLARE
    v_helper RECORD;
BEGIN
    -- Only process public jobs
    IF NEW.is_private = false THEN
        -- Find all helpers with this job's category as active
        FOR v_helper IN
            SELECT DISTINCT u.id, u.display_name, u.fcm_token
            FROM users u
            JOIN helper_job_types hjt ON u.id = hjt.helper_id
            WHERE u.user_type = 'helper'
              AND u.id != NEW.helpee_id  -- Not the job creator
              AND hjt.job_category_id = NEW.category_id
              AND hjt.is_active = true  -- Only active categories
              AND u.notification_enabled = true
        LOOP
            -- Create notification for each matching helper
            INSERT INTO notifications (
                user_id, 
                title, 
                message, 
                notification_type,
                related_job_id, 
                is_read, 
                created_at
            ) VALUES (
                v_helper.id,
                'New Job Available! 🎯',
                format('%s - %s', NEW.title, COALESCE(NEW.location_address, 'Location TBD')),
                'new_job_available',
                NEW.id,
                false,
                NOW()
            );
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new job notifications
CREATE TRIGGER notify_helpers_of_new_job_trigger
    AFTER INSERT ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION notify_helpers_of_new_job();

-- ====================================================================================
-- Grant permissions
-- ====================================================================================
GRANT EXECUTE ON FUNCTION get_public_jobs_for_helper(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_private_jobs_for_helper(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_job_status_notification(UUID, VARCHAR, VARCHAR) TO authenticated;

-- ====================================================================================
-- Test the filtering (should return 0 for helper with 'trh' seeing 'WORK' jobs)
-- ====================================================================================
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM get_public_jobs_for_helper('29e2adb3-4910-4c83-804b-0014b1c4598a');
    
    RAISE NOTICE 'Helper should see % public jobs (should be 0 if categories dont match)', v_count;
END $$; 