-- Fix Job Creation Notifications Migration
-- Purpose: Fix the job creation notification trigger to use correct column names

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS job_creation_notification_trigger ON jobs;
DROP FUNCTION IF EXISTS notify_new_job();

-- Create updated function to notify eligible helpers about new jobs
CREATE OR REPLACE FUNCTION notify_new_job()
RETURNS TRIGGER AS $$
DECLARE
    v_helpee_name TEXT;
    v_helper_record RECORD;
BEGIN
    -- Get helpee name for notification message
    SELECT display_name INTO v_helpee_name 
    FROM users 
    WHERE id = NEW.helpee_id;

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

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new job notifications
CREATE TRIGGER job_creation_notification_trigger
    AFTER INSERT ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_job();

-- Add comment
COMMENT ON FUNCTION notify_new_job() IS 'Trigger function to create notifications when new jobs are posted';

-- Verify the setup
DO $$ 
BEGIN
    -- Check if trigger exists
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'job_creation_notification_trigger'
    ) THEN
        RAISE NOTICE '✅ Job creation notification trigger created successfully';
    ELSE
        RAISE EXCEPTION '❌ Failed to create job creation notification trigger';
    END IF;
END $$; 