-- Add Job Creation Notifications Migration
-- Purpose: Create notifications when new jobs are posted

-- Create function to notify eligible helpers about new jobs
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
        is_read,
        created_at,
        notification_category,
        is_push_sent
    ) VALUES (
        NEW.helpee_id,
        'Job Request Created',
        'Your job request "' || NEW.title || '" has been created successfully',
        'job_created',
        NEW.id,
        false,
        NOW(),
        'job_status',
        false
    );

    -- If job is not private, notify all eligible helpers
    IF NOT NEW.is_private THEN
        -- Loop through helpers who have this job category enabled
        FOR v_helper_record IN 
            SELECT DISTINCT h.helper_id 
            FROM helper_job_types h
            WHERE h.job_category_id = NEW.job_category_id
            AND h.is_active = true
        LOOP
            -- Create notification for each eligible helper
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
                v_helper_record.helper_id,
                'New Job Available',
                'A new job request "' || NEW.title || '" has been posted that matches your skills',
                'new_job_available',
                NEW.id,
                false,
                NOW(),
                'job_status',
                false
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

-- Add new notification template for job creation
INSERT INTO notification_templates (template_key, title_en, body_en, title_si, body_si, title_ta, body_ta, notification_type)
VALUES 
('job_created', 'Job Request Created', 'Your job request "{job_title}" has been created successfully', 'රැකියා ඉල්ලීම සාර්ථකයි', 'ඔබේ "{job_title}" රැකියා ඉල්ලීම සාර්ථකව සාදා ඇත', 'வேலை கோரிக்கை உருவாக்கப்பட்டது', 'உங்கள் "{job_title}" வேலை கோரிக்கை வெற்றிகரமாக உருவாக்கப்பட்டது', 'job_created'),
('new_job_available', 'New Job Available', 'A new job request "{job_title}" matches your skills', 'නව රැකියා ඉල්ලීමක්', '"{job_title}" නව රැකියා ඉල්ලීමක් ඔබේ කුසලතාවලට ගැලපේ', 'புதிய வேலை கிடைக்கிறது', '"{job_title}" என்ற புதிய வேலை கோரிக்கை உங்கள் திறன்களுடன் பொருந்துகிறது', 'new_job_available')
ON CONFLICT (template_key) DO UPDATE SET
    title_en = EXCLUDED.title_en,
    body_en = EXCLUDED.body_en,
    title_si = EXCLUDED.title_si,
    body_si = EXCLUDED.body_si,
    title_ta = EXCLUDED.title_ta,
    body_ta = EXCLUDED.body_ta,
    updated_at = NOW();

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