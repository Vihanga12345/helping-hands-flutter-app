-- Fix helper notification trigger
-- The error was due to incorrect column reference h.user_id which doesn't exist
-- We need to use the correct column name from the helpers table

-- Drop existing triggers first
DROP TRIGGER IF EXISTS notify_helpers_on_job_creation ON jobs;
DROP FUNCTION IF EXISTS notify_helpers_on_job_creation();

-- Recreate the function with correct column references
CREATE OR REPLACE FUNCTION notify_helpers_on_job_creation()
RETURNS TRIGGER AS $$
DECLARE
    helper_record RECORD;
BEGIN
    -- For public jobs, notify all helpers who match the job category
    IF NEW.is_private = false THEN
        FOR helper_record IN (
            SELECT DISTINCT h.id as helper_id, u.id as user_id
            FROM helpers h
            JOIN users u ON h.user_id = u.id
            JOIN helper_job_categories hjc ON h.id = hjc.helper_id
            JOIN job_categories jc ON hjc.category_id = jc.id
            WHERE jc.id = NEW.category_id
            AND h.is_verified = true
            AND h.is_active = true
        ) LOOP
            -- Insert notification for each eligible helper
            INSERT INTO notifications (
                user_id,
                title,
                message,
                notification_type,
                related_job_id,
                is_read
            ) VALUES (
                helper_record.user_id,
                'New Job Available',
                'A new job matching your skills has been posted: ' || NEW.title,
                'new_job',
                NEW.id,
                false
            );
        END LOOP;
    -- For private jobs, notify only the assigned helper
    ELSIF NEW.is_private = true AND NEW.assigned_helper_id IS NOT NULL THEN
        INSERT INTO notifications (
            user_id,
            title,
            message,
            notification_type,
            related_job_id,
            is_read
        )
        SELECT 
            u.id,
            'Private Job Request',
            'You have received a private job request: ' || NEW.title,
            'private_job_request',
            NEW.id,
            false
        FROM helpers h
        JOIN users u ON h.user_id = u.id
        WHERE h.id = NEW.assigned_helper_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER notify_helpers_on_job_creation
    AFTER INSERT ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION notify_helpers_on_job_creation();

-- Verify the function exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_proc 
        WHERE proname = 'notify_helpers_on_job_creation'
    ) THEN
        RAISE EXCEPTION 'Function notify_helpers_on_job_creation was not created properly';
    END IF;
END $$; 