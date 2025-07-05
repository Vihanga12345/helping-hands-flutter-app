-- Migration: Fix job status filtering for ongoing jobs
-- Date: January 2025
-- Purpose: Ensure accepted and started jobs appear in ongoing activity tabs

-- Update any jobs with status 'ongoing' to 'started' for clarity
-- Since we're using 'accepted' and 'started' for ongoing jobs
UPDATE jobs 
SET status = 'started' 
WHERE status = 'ongoing';

-- Add index for better job filtering performance
CREATE INDEX IF NOT EXISTS idx_jobs_status_helper ON jobs(assigned_helper_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_status_helpee ON jobs(helpee_id, status);

-- Add comment about status flow
COMMENT ON COLUMN jobs.status IS 'Job status flow: pending -> accepted -> started -> completed/cancelled. Use accepted+started for ongoing filters.';
COMMENT ON COLUMN jobs.timer_status IS 'Timer status: not_started -> running -> paused -> completed. Independent of job status.';

-- Update existing paused jobs to have proper timer_status
UPDATE jobs 
SET timer_status = 'paused' 
WHERE status = 'started' AND timer_status = 'not_started' AND paused_at IS NOT NULL;

-- Update running jobs
UPDATE jobs 
SET timer_status = 'running' 
WHERE status = 'started' AND timer_status = 'not_started' AND started_at IS NOT NULL AND paused_at IS NULL;

-- Ensure completed jobs have completed timer status
UPDATE jobs 
SET timer_status = 'completed' 
WHERE status = 'completed' AND timer_status != 'completed'; 