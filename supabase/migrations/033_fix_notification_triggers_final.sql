-- Fix Notification Triggers Migration (FINAL)
-- Purpose: Fix notification triggers to ensure proper notification creation

-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS job_status_notification_trigger ON jobs;
DROP FUNCTION IF EXISTS notify_job_status_change();

-- Create the job status notification trigger function
CREATE OR REPLACE FUNCTION notify_job_status_change()
RETURNS TRIGGER AS $$
DECLARE
    v_helper_name TEXT;
    v_job_title TEXT;
    v_template_title TEXT;
    v_template_body TEXT;
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
        -- Get template for job accepted
        SELECT title_en, body_en INTO v_template_title, v_template_body
        FROM notification_templates
        WHERE template_key = 'job_request_accepted';

        -- Replace placeholders in template
        v_template_body := REPLACE(v_template_body, '{job_title}', v_job_title);
        v_template_body := REPLACE(v_template_body, '{helper_name}', v_helper_name);

        -- Notify helpee
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
            NEW.helpee_id,
            v_template_title,
            v_template_body,
            'job_accepted',
            NEW.id,
            false,
            NOW(),
            'job_status',
            false
        );

        -- Notify helper
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
            NEW.assigned_helper_id,
            'Job Accepted Successfully',
            'You have accepted the job request "' || v_job_title || '"',
            'job_accepted',
            NEW.id,
            false,
            NOW(),
            'job_status',
            false
        );
    END IF;

    IF NEW.status = 'started' AND OLD.status = 'accepted' THEN
        -- Get template for job started
        SELECT title_en, body_en INTO v_template_title, v_template_body
        FROM notification_templates
        WHERE template_key = 'job_started';

        -- Replace placeholders in template
        v_template_body := REPLACE(v_template_body, '{job_title}', v_job_title);
        v_template_body := REPLACE(v_template_body, '{helper_name}', v_helper_name);

        -- Notify helpee
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
            NEW.helpee_id,
            v_template_title,
            v_template_body,
            'job_started',
            NEW.id,
            false,
            NOW(),
            'job_status',
            false
        );

        -- Notify helper
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
            NEW.assigned_helper_id,
            'Job Started',
            'You have started working on "' || v_job_title || '"',
            'job_started',
            NEW.id,
            false,
            NOW(),
            'job_status',
            false
        );
    END IF;

    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Get template for job completed
        SELECT title_en, body_en INTO v_template_title, v_template_body
        FROM notification_templates
        WHERE template_key = 'job_completed';

        -- Replace placeholders in template
        v_template_body := REPLACE(v_template_body, '{job_title}', v_job_title);
        v_template_body := REPLACE(v_template_body, '{helper_name}', v_helper_name);

        -- Notify helpee
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
            NEW.helpee_id,
            v_template_title,
            v_template_body,
            'job_completed',
            NEW.id,
            false,
            NOW(),
            'job_status',
            false
        );

        -- Notify helper
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
            NEW.assigned_helper_id,
            'Job Completed',
            'You have completed the job "' || v_job_title || '"',
            'job_completed',
            NEW.id,
            false,
            NOW(),
            'job_status',
            false
        );
    END IF;

    IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
        -- Get template for job cancelled
        SELECT title_en, body_en INTO v_template_title, v_template_body
        FROM notification_templates
        WHERE template_key = 'job_request_rejected';

        -- Replace placeholders in template
        v_template_body := REPLACE(v_template_body, '{job_title}', v_job_title);

        -- Notify helpee
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
            NEW.helpee_id,
            v_template_title,
            v_template_body,
            'job_cancelled',
            NEW.id,
            false,
            NOW(),
            'job_status',
            false
        );

        -- Notify helper if assigned
        IF NEW.assigned_helper_id IS NOT NULL THEN
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
                NEW.assigned_helper_id,
                'Job Cancelled',
                'The job "' || v_job_title || '" has been cancelled',
                'job_cancelled',
                NEW.id,
                false,
                NOW(),
                'job_status',
                false
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