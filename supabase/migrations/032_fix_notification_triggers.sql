-- Fix Notification Triggers Migration
-- Purpose: Consolidate and fix notification triggers to ensure proper notification creation

-- First, drop existing triggers and functions to avoid conflicts
DROP TRIGGER IF EXISTS job_status_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS trigger_create_notification_preferences ON users;
DROP FUNCTION IF EXISTS notify_job_status_change();
DROP FUNCTION IF EXISTS create_job_notification();

-- Create the notification creation function with proper parameters
CREATE OR REPLACE FUNCTION create_job_notification(
    p_user_id UUID,
    p_title TEXT,
    p_message TEXT,
    p_notification_type TEXT,
    p_job_id UUID
) RETURNS void AS $$
BEGIN
    INSERT INTO notifications (
        user_id,
        title,
        message,
        notification_type,
        related_job_id,
        is_read,
        created_at,
        notification_category,
        is_push_sent
    ) VALUES (
        p_user_id,
        p_title,
        p_message,
        p_notification_type,
        p_job_id,
        false,
        NOW(),
        'job_status',
        false
    );
END;
$$ LANGUAGE plpgsql;

-- Create the job status notification trigger function
CREATE OR REPLACE FUNCTION notify_job_status_change()
RETURNS TRIGGER AS $$
DECLARE
    v_helper_name TEXT;
    v_job_title TEXT;
BEGIN
    -- Get helper name and job title for notification messages
    SELECT display_name INTO v_helper_name 
    FROM users 
    WHERE id = NEW.assigned_helper_id;

    SELECT title INTO v_job_title 
    FROM jobs 
    WHERE id = NEW.id;

    -- Handle different status changes
    IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
        -- Notify helpee
        PERFORM create_job_notification(
            NEW.helpee_id,
            'Job Request Accepted',
            'Your job request "' || v_job_title || '" has been accepted by ' || v_helper_name,
            'job_accepted',
            NEW.id
        );
        -- Notify helper
        PERFORM create_job_notification(
            NEW.assigned_helper_id,
            'Job Accepted Successfully',
            'You have accepted the job request "' || v_job_title || '"',
            'job_accepted',
            NEW.id
        );
    END IF;

    IF NEW.status = 'started' AND OLD.status = 'accepted' THEN
        -- Notify helpee
        PERFORM create_job_notification(
            NEW.helpee_id,
            'Job Started',
            v_helper_name || ' has started working on "' || v_job_title || '"',
            'job_started',
            NEW.id
        );
        -- Notify helper
        PERFORM create_job_notification(
            NEW.assigned_helper_id,
            'Job Started',
            'You have started working on "' || v_job_title || '"',
            'job_started',
            NEW.id
        );
    END IF;

    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Notify helpee
        PERFORM create_job_notification(
            NEW.helpee_id,
            'Job Completed',
            'Your job "' || v_job_title || '" has been completed by ' || v_helper_name,
            'job_completed',
            NEW.id
        );
        -- Notify helper
        PERFORM create_job_notification(
            NEW.assigned_helper_id,
            'Job Completed',
            'You have completed the job "' || v_job_title || '"',
            'job_completed',
            NEW.id
        );
    END IF;

    IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
        -- Notify both parties
        PERFORM create_job_notification(
            NEW.helpee_id,
            'Job Cancelled',
            'The job "' || v_job_title || '" has been cancelled',
            'job_cancelled',
            NEW.id
        );
        IF NEW.assigned_helper_id IS NOT NULL THEN
            PERFORM create_job_notification(
                NEW.assigned_helper_id,
                'Job Cancelled',
                'The job "' || v_job_title || '" has been cancelled',
                'job_cancelled',
                NEW.id
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on jobs table
CREATE TRIGGER job_status_notification_trigger
    AFTER UPDATE OF status ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION notify_job_status_change();

-- Create index for faster notification queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_created_at 
ON notifications(user_id, created_at DESC);

-- Verify the setup
DO $$ 
BEGIN
    -- Check if trigger exists
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'job_status_notification_trigger'
    ) THEN
        RAISE NOTICE '✅ Job status notification trigger created successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to create job status notification trigger';
    END IF;
END $$; 