-- Migration: Add notification triggers for job events
-- Date: 2024
-- Purpose: Automatically create notifications for job status changes

-- Function to create notifications
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
        created_at
    ) VALUES (
        p_user_id,
        p_title,
        p_message,
        p_notification_type,
        p_job_id,
        false,
        NOW()
    );
END;
$$ LANGUAGE plpgsql;

-- Trigger function for job status changes
CREATE OR REPLACE FUNCTION notify_job_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Job accepted notification
    IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
        -- Notify helpee
        PERFORM create_job_notification(
            NEW.helpee_id,
            'Job Request Accepted',
            'A helper has accepted your job request.',
            'job_accepted',
            NEW.id
        );
        -- Notify helper
        PERFORM create_job_notification(
            NEW.assigned_helper_id,
            'Job Accepted Successfully',
            'You have accepted a new job request.',
            'job_accepted',
            NEW.id
        );
    END IF;

    -- Job started notification
    IF NEW.status = 'started' AND OLD.status = 'accepted' THEN
        -- Notify helpee
        PERFORM create_job_notification(
            NEW.helpee_id,
            'Job Started',
            'Your helper has started working on your job.',
            'job_started',
            NEW.id
        );
        -- Notify helper
        PERFORM create_job_notification(
            NEW.assigned_helper_id,
            'Job Started',
            'You have started working on the job.',
            'job_started',
            NEW.id
        );
    END IF;

    -- Job completed notification
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Notify helpee
        PERFORM create_job_notification(
            NEW.helpee_id,
            'Job Completed',
            'Your job has been marked as completed.',
            'job_completed',
            NEW.id
        );
        -- Notify helper
        PERFORM create_job_notification(
            NEW.assigned_helper_id,
            'Job Completed',
            'You have completed the job.',
            'job_completed',
            NEW.id
        );
    END IF;

    -- Job cancelled notification
    IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
        -- Notify both parties
        PERFORM create_job_notification(
            NEW.helpee_id,
            'Job Cancelled',
            'The job has been cancelled.',
            'job_cancelled',
            NEW.id
        );
        IF NEW.assigned_helper_id IS NOT NULL THEN
            PERFORM create_job_notification(
                NEW.assigned_helper_id,
                'Job Cancelled',
                'The job has been cancelled.',
                'job_cancelled',
                NEW.id
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on jobs table
DROP TRIGGER IF EXISTS job_status_notification_trigger ON jobs;
CREATE TRIGGER job_status_notification_trigger
    AFTER UPDATE OF status ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION notify_job_status_change();

-- Create index for faster notification queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_created_at 
ON notifications(user_id, created_at DESC);

-- Add comment
COMMENT ON FUNCTION notify_job_status_change() IS 'Trigger function to create notifications when job status changes'; 