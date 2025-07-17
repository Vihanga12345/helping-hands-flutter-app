-- Fix Notification Columns Migration
-- Purpose: Fix notification columns and consolidate triggers

-- Drop all existing notification triggers
DROP TRIGGER IF EXISTS job_creation_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS job_status_notification_trigger ON jobs;
DROP FUNCTION IF EXISTS notify_new_job();
DROP FUNCTION IF EXISTS notify_job_status_change();

-- Create consolidated job notification function
CREATE OR REPLACE FUNCTION notify_job_events()
RETURNS TRIGGER AS $$
DECLARE
    v_helpee_name TEXT;
    v_helper_record RECORD;
BEGIN
    -- Get helpee name for notification message
    SELECT display_name INTO v_helpee_name 
    FROM users 
    WHERE id = NEW.helpee_id;

    -- Handle new job creation
    IF TG_OP = 'INSERT' THEN
        -- Create notification for helpee
        INSERT INTO notifications (
            user_id,
            title,
            message,
            notification_type,
            related_job_id,
            related_user_id,
            is_read,
            action_url
        ) VALUES (
            NEW.helpee_id,
            'Job Request Created',
            'Your job request "' || NEW.title || '" has been created successfully.',
            'job_created',
            NEW.id,
            NEW.helpee_id,
            false,
            '/helpee/jobs/' || NEW.id
        );

        -- Notify eligible helpers if job is public
        IF NOT NEW.is_private THEN
            FOR v_helper_record IN 
                SELECT DISTINCT h.user_id
                FROM helper_job_types h
                JOIN users u ON h.user_id = u.id
                WHERE h.job_category_id = NEW.category_id
                AND u.user_type = 'helper'
                AND u.is_active = true
            LOOP
                INSERT INTO notifications (
                    user_id,
                    title,
                    message,
                    notification_type,
                    related_job_id,
                    related_user_id,
                    is_read,
                    action_url
                ) VALUES (
                    v_helper_record.user_id,
                    'New Job Available',
                    'A new ' || NEW.job_category_name || ' job is available from ' || v_helpee_name || '.',
                    'new_job_available',
                    NEW.id,
                    NEW.helpee_id,
                    false,
                    '/helper/jobs/' || NEW.id
                );
            END LOOP;
        END IF;
    END IF;

    -- Handle job status changes
    IF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
        -- Create notification for helpee
        INSERT INTO notifications (
            user_id,
            title,
            message,
            notification_type,
            related_job_id,
            related_user_id,
            is_read,
            action_url
        ) VALUES (
            NEW.helpee_id,
            'Job Status Updated',
            'Your job "' || NEW.title || '" status has been updated to ' || NEW.status || '.',
            'job_status_change',
            NEW.id,
            NEW.helpee_id,
            false,
            '/helpee/jobs/' || NEW.id
        );

        -- Create notification for helper if assigned
        IF NEW.assigned_helper_id IS NOT NULL THEN
            INSERT INTO notifications (
                user_id,
                title,
                message,
                notification_type,
                related_job_id,
                related_user_id,
                is_read,
                action_url
            ) VALUES (
                NEW.assigned_helper_id,
                'Job Status Updated',
                'Job "' || NEW.title || '" status has been updated to ' || NEW.status || '.',
                'job_status_change',
                NEW.id,
                NEW.helpee_id,
                false,
                '/helper/jobs/' || NEW.id
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create single trigger for all job events
CREATE TRIGGER job_notification_trigger
    AFTER INSERT OR UPDATE ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION notify_job_events();

-- Add comment
COMMENT ON FUNCTION notify_job_events() IS 'Consolidated trigger function to handle all job-related notifications'; 