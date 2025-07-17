-- Remove job notification triggers that are blocking job creation
-- This will allow jobs to be created without notification overhead

-- Drop the notification trigger
DROP TRIGGER IF EXISTS notify_helpers_on_job_creation ON jobs;

-- Drop the notification function
DROP FUNCTION IF EXISTS notify_helpers_on_job_creation();

-- Verify trigger is removed
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'notify_helpers_on_job_creation'
    ) THEN
        RAISE EXCEPTION 'Failed to remove notification trigger';
    END IF;
END $$; 