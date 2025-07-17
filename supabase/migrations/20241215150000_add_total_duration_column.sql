-- Add total_duration column to jobs table
-- This will store the calculated duration of completed jobs in minutes

ALTER TABLE jobs 
ADD COLUMN total_duration INTEGER DEFAULT NULL;

-- Add comment for clarity
COMMENT ON COLUMN jobs.total_duration IS 'Total duration of the job in minutes, calculated from actual_start_time and actual_end_time';

-- Create index for performance when querying by duration
CREATE INDEX idx_jobs_total_duration ON jobs(total_duration) WHERE total_duration IS NOT NULL; 