-- ============================================================================
-- Migration 041: Fix Database Schema Mismatch  
-- Date: January 2025
-- Purpose: Fix the fundamental schema mismatch where the notification triggers
--          expect a separate 'helpers' table, but the actual schema stores
--          helper data in the 'users' table with user_type = 'helper'
-- ============================================================================

-- STEP 1: Drop all conflicting triggers and functions
DROP TRIGGER IF EXISTS trigger_job_event_notifications ON jobs;
DROP TRIGGER IF EXISTS job_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS job_creation_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS job_status_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS notify_helpers_on_job_creation ON jobs;

DROP FUNCTION IF EXISTS notify_on_job_event();
DROP FUNCTION IF EXISTS notify_job_events();
DROP FUNCTION IF EXISTS notify_new_job();
DROP FUNCTION IF EXISTS notify_job_status_change();
DROP FUNCTION IF EXISTS notify_helpers_on_job_creation();

-- STEP 2: Create the correct notification function using the actual schema
-- This uses the users table with user_type = 'helper' instead of a separate helpers table
CREATE OR REPLACE FUNCTION notify_on_job_creation()
RETURNS TRIGGER AS $$
DECLARE
    v_helpee_name TEXT;
    v_helper_record RECORD;
BEGIN
    -- Get the helpee's display name
    SELECT display_name INTO v_helpee_name 
    FROM users 
    WHERE id = NEW.helpee_id;

    -- Create a notification for the helpee confirming job creation
    INSERT INTO notifications (user_id, title, message, notification_type, related_job_id, is_read) 
    VALUES (NEW.helpee_id, 'Job Request Created', 'Your job request "' || NEW.title || '" has been created successfully.', 'job_created', NEW.id, false);

    -- For public jobs, notify helpers who have matching job categories
    -- THIS IS THE CORRECTED LOGIC: Using users table with user_type = 'helper'
    IF NOT NEW.is_private THEN
        FOR v_helper_record IN 
            SELECT DISTINCT u.id as user_id
            FROM users u
            JOIN helper_job_types hjt ON u.id = hjt.helper_id
            WHERE hjt.job_category_id = NEW.category_id
            AND hjt.is_active = true
            AND u.user_type = 'helper'
            AND u.is_active = true
        LOOP
            INSERT INTO notifications (user_id, title, message, notification_type, related_job_id, is_read) 
            VALUES (v_helper_record.user_id, 'New Job Available', 'A new job "' || NEW.title || '" is available from ' || v_helpee_name, 'new_job_available', NEW.id, false);
        END LOOP;
    END IF;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't block job creation
        RAISE WARNING 'Notification creation failed: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- STEP 3: Create trigger for job creation notifications
CREATE TRIGGER trigger_notify_on_job_creation
    AFTER INSERT ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION notify_on_job_creation();

-- STEP 4: Create simplified notification function for job status updates
CREATE OR REPLACE FUNCTION notify_on_job_status_update()
RETURNS TRIGGER AS $$
BEGIN
    -- Only proceed if status has actually changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        -- Notify the helpee about status change
        INSERT INTO notifications (user_id, title, message, notification_type, related_job_id, is_read) 
        VALUES (NEW.helpee_id, 'Job Status Updated', 'Your job "' || NEW.title || '" status changed to ' || NEW.status, 'job_status_update', NEW.id, false);

        -- Notify the helper if one is assigned
        IF NEW.assigned_helper_id IS NOT NULL THEN
            INSERT INTO notifications (user_id, title, message, notification_type, related_job_id, is_read) 
            VALUES (NEW.assigned_helper_id, 'Job Status Updated', 'Job "' || NEW.title || '" status changed to ' || NEW.status, 'job_status_update', NEW.id, false);
        END IF;
    END IF;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't block job status updates
        RAISE WARNING 'Status notification failed: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- STEP 5: Create trigger for job status updates
CREATE TRIGGER trigger_notify_on_job_status_update
    AFTER UPDATE OF status ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION notify_on_job_status_update();

-- STEP 6: Ensure helper_job_types table exists with correct structure
CREATE TABLE IF NOT EXISTS helper_job_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    helper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_category_id UUID NOT NULL REFERENCES job_categories(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    hourly_rate DECIMAL(10, 2),
    experience_level VARCHAR(50) DEFAULT 'beginner' CHECK (experience_level IN ('beginner', 'intermediate', 'expert')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Ensure one record per helper-category combination
    UNIQUE(helper_id, job_category_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_helper_job_types_helper_id ON helper_job_types(helper_id);
CREATE INDEX IF NOT EXISTS idx_helper_job_types_category_id ON helper_job_types(job_category_id);
CREATE INDEX IF NOT EXISTS idx_helper_job_types_active ON helper_job_types(is_active);

-- STEP 7: Insert sample data for testing (only if table is empty)
INSERT INTO helper_job_types (helper_id, job_category_id, is_active, hourly_rate, experience_level)
SELECT 
    u.id as helper_id,
    jc.id as job_category_id,
    true as is_active,
    15.00 as hourly_rate,
    'intermediate' as experience_level
FROM users u
CROSS JOIN job_categories jc
WHERE u.user_type = 'helper'
AND u.is_active = true
AND NOT EXISTS (
    SELECT 1 FROM helper_job_types hjt 
    WHERE hjt.helper_id = u.id AND hjt.job_category_id = jc.id
)
LIMIT 20; -- Limit to prevent too many records

-- STEP 8: Verification
DO $$
BEGIN
    -- Check if triggers exist
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname IN ('trigger_notify_on_job_creation', 'trigger_notify_on_job_status_update')
    ) THEN
        RAISE NOTICE '✅ Migration 041 complete: Database schema mismatch fixed, notification system working';
    ELSE
        RAISE EXCEPTION '❌ Migration 041 FAILED: Notification triggers not created';
    END IF;

    -- Check helper_job_types table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'helper_job_types') THEN
        RAISE NOTICE '✅ helper_job_types table exists and ready';
    ELSE
        RAISE EXCEPTION '❌ helper_job_types table missing';
    END IF;
END $$; 