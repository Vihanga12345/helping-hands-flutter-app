-- Migration: Add job timer functionality
-- Date: January 2025
-- Purpose: Add timer columns to jobs table for proper time tracking

-- Add timer-related columns to jobs table
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS paused_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS resumed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS total_elapsed_seconds INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS timer_status VARCHAR(20) DEFAULT 'not_started' CHECK (timer_status IN ('not_started', 'running', 'paused', 'completed'));

-- Create index for timer queries
CREATE INDEX IF NOT EXISTS idx_jobs_timer_status ON jobs(timer_status);
CREATE INDEX IF NOT EXISTS idx_jobs_started_at ON jobs(started_at);

-- Add comments for documentation
COMMENT ON COLUMN jobs.started_at IS 'Timestamp when job timer was first started';
COMMENT ON COLUMN jobs.paused_at IS 'Timestamp when job was last paused';
COMMENT ON COLUMN jobs.resumed_at IS 'Timestamp when job was last resumed after pause';
COMMENT ON COLUMN jobs.completed_at IS 'Timestamp when job was completed';
COMMENT ON COLUMN jobs.total_elapsed_seconds IS 'Total elapsed time in seconds (excluding paused time)';
COMMENT ON COLUMN jobs.timer_status IS 'Current timer status: not_started, running, paused, completed';

-- Update existing jobs to have default timer status
UPDATE jobs 
SET timer_status = CASE 
  WHEN status = 'started' THEN 'running'
  WHEN status = 'completed' THEN 'completed'
  ELSE 'not_started'
END
WHERE timer_status = 'not_started';

-- Function to calculate elapsed time for a job
CREATE OR REPLACE FUNCTION calculate_job_elapsed_time(job_id UUID)
RETURNS INTEGER AS $$
DECLARE
  job_record RECORD;
  elapsed_seconds INTEGER := 0;
BEGIN
  SELECT * INTO job_record FROM jobs WHERE id = job_id;
  
  IF job_record.started_at IS NULL THEN
    RETURN 0;
  END IF;
  
  -- If job is completed, return stored total_elapsed_seconds
  IF job_record.timer_status = 'completed' THEN
    RETURN COALESCE(job_record.total_elapsed_seconds, 0);
  END IF;
  
  -- If job is currently running, calculate time since started/resumed
  IF job_record.timer_status = 'running' THEN
    IF job_record.resumed_at IS NOT NULL THEN
      elapsed_seconds := COALESCE(job_record.total_elapsed_seconds, 0) + 
                        EXTRACT(EPOCH FROM (NOW() - job_record.resumed_at))::INTEGER;
    ELSE
      elapsed_seconds := EXTRACT(EPOCH FROM (NOW() - job_record.started_at))::INTEGER;
    END IF;
  ELSE
    -- Job is paused, return stored elapsed time
    elapsed_seconds := COALESCE(job_record.total_elapsed_seconds, 0);
  END IF;
  
  RETURN elapsed_seconds;
END;
$$ LANGUAGE plpgsql;

-- Function to format elapsed time as HH:MM:SS
CREATE OR REPLACE FUNCTION format_elapsed_time(seconds INTEGER)
RETURNS TEXT AS $$
DECLARE
  hours INTEGER;
  minutes INTEGER;
  remaining_seconds INTEGER;
BEGIN
  hours := seconds / 3600;
  minutes := (seconds % 3600) / 60;
  remaining_seconds := seconds % 60;
  
  RETURN LPAD(hours::TEXT, 2, '0') || ':' || 
         LPAD(minutes::TEXT, 2, '0') || ':' || 
         LPAD(remaining_seconds::TEXT, 2, '0');
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update timer status when job status changes
CREATE OR REPLACE FUNCTION update_timer_status_on_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Update timer status based on job status
  IF NEW.status = 'started' AND OLD.status != 'started' THEN
    NEW.timer_status := 'running';
    IF NEW.started_at IS NULL THEN
      NEW.started_at := NOW();
    END IF;
  ELSIF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    NEW.timer_status := 'completed';
    NEW.completed_at := NOW();
    -- Update total elapsed time if job was running
    IF OLD.timer_status = 'running' THEN
      NEW.total_elapsed_seconds := calculate_job_elapsed_time(NEW.id);
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS timer_status_update_trigger ON jobs;
CREATE TRIGGER timer_status_update_trigger
  BEFORE UPDATE ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION update_timer_status_on_status_change();

-- Create view for job timer information
CREATE OR REPLACE VIEW job_timer_info AS
SELECT 
  j.id,
  j.title,
  j.status,
  j.timer_status,
  j.started_at,
  j.paused_at,
  j.resumed_at,
  j.completed_at,
  j.total_elapsed_seconds,
  calculate_job_elapsed_time(j.id) as current_elapsed_seconds,
  format_elapsed_time(calculate_job_elapsed_time(j.id)) as formatted_elapsed_time,
  CASE 
    WHEN j.timer_status = 'running' THEN true
    ELSE false
  END as is_timer_running
FROM jobs j;

-- Grant permissions
GRANT SELECT ON job_timer_info TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_job_elapsed_time(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION format_elapsed_time(INTEGER) TO authenticated; 