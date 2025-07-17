-- Helping Hands App - Private Job Request Feature Enhancement
-- Migration: 002_private_job_enhancements.sql

-- Add helper assignment tracking columns to jobs table
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS assigned_helper_email VARCHAR(255);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helper_selection_method VARCHAR(20) CHECK (helper_selection_method IN ('search', 'direct', 'application'));

-- Create performance indexes for faster private job queries
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_helper_email ON jobs(assigned_helper_email);
CREATE INDEX IF NOT EXISTS idx_jobs_job_type_status ON jobs(job_type, status);

-- Update existing jobs to have selection method
UPDATE jobs SET helper_selection_method = 'application' WHERE helper_selection_method IS NULL AND job_type = 'public';
UPDATE jobs SET helper_selection_method = 'direct' WHERE helper_selection_method IS NULL AND job_type = 'private';

-- Enhanced function to get private jobs for specific helper
CREATE OR REPLACE FUNCTION get_private_jobs_for_helper_enhanced(helper_user_id UUID)
RETURNS TABLE (
  job_data JSON
) AS $$
BEGIN
  RETURN QUERY
  SELECT to_json(j.*) as job_data
  FROM jobs j
  LEFT JOIN users helpee ON j.helpee_id = helpee.id
  LEFT JOIN users helper ON j.assigned_helper_id = helper.id
  WHERE (
    j.assigned_helper_id = helper_user_id OR 
    j.invited_helper_email = (SELECT email FROM users WHERE id = helper_user_id)
  )
  AND j.job_type = 'private'
  AND j.status IN ('pending', 'accepted')
  ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get helper email by user id
CREATE OR REPLACE FUNCTION get_helper_email_by_id(helper_user_id UUID)
RETURNS VARCHAR(255) AS $$
BEGIN
  RETURN (SELECT email FROM users WHERE id = helper_user_id);
END;
$$ LANGUAGE plpgsql;

-- Function to get private jobs assigned to a helper (by email or ID)
CREATE OR REPLACE FUNCTION get_assigned_private_jobs(helper_user_id UUID)
RETURNS TABLE (
  id UUID,
  title VARCHAR(200),
  description TEXT,
  job_type VARCHAR(20),
  status VARCHAR(20),
  hourly_rate DECIMAL(10,2),
  scheduled_date DATE,
  scheduled_start_time TIME,
  location_address TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  helpee_data JSON,
  category_data JSON
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    j.id,
    j.title,
    j.description,
    j.job_type,
    j.status,
    j.hourly_rate,
    j.scheduled_date,
    j.scheduled_start_time,
    j.location_address,
    j.created_at,
    to_json(helpee.*) as helpee_data,
    to_json(category.*) as category_data
  FROM jobs j
  LEFT JOIN users helpee ON j.helpee_id = helpee.id
  LEFT JOIN job_categories category ON j.category_id = category.id
  WHERE (
    j.assigned_helper_id = helper_user_id OR 
    j.invited_helper_email = (SELECT email FROM users WHERE id = helper_user_id) OR
    j.assigned_helper_email = (SELECT email FROM users WHERE id = helper_user_id)
  )
  AND j.job_type = 'private'
  AND j.status IN ('pending', 'accepted')
  ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to update job assignment
CREATE OR REPLACE FUNCTION assign_helper_to_job(
  job_id UUID,
  helper_id UUID,
  helper_email VARCHAR(255)
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE jobs 
  SET 
    assigned_helper_id = helper_id,
    assigned_helper_email = helper_email,
    helper_selection_method = 'search',
    updated_at = NOW()
  WHERE id = job_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Create notification function for private job assignments
CREATE OR REPLACE FUNCTION create_private_job_notification(
  helper_id UUID,
  job_id UUID,
  job_title VARCHAR(200),
  helpee_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  INSERT INTO notifications (
    user_id,
    title,
    message,
    notification_type,
    related_job_id,
    related_user_id,
    is_read,
    created_at
  ) VALUES (
    helper_id,
    'New Private Job Request',
    'You have been invited to a private job: ' || job_title,
    'private_job_request',
    job_id,
    helpee_id,
    false,
    NOW()
  );
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Update trigger to automatically set helper_selection_method based on job_type
CREATE OR REPLACE FUNCTION set_default_helper_selection_method()
RETURNS TRIGGER AS $$
BEGIN
  -- Set default helper_selection_method if not provided
  IF NEW.helper_selection_method IS NULL THEN
    IF NEW.job_type = 'private' THEN
      NEW.helper_selection_method = 'search';
    ELSE
      NEW.helper_selection_method = 'application';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for jobs table
DROP TRIGGER IF EXISTS set_helper_selection_method_trigger ON jobs;
CREATE TRIGGER set_helper_selection_method_trigger
  BEFORE INSERT OR UPDATE ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION set_default_helper_selection_method();

-- Add comments for documentation
COMMENT ON COLUMN jobs.assigned_helper_email IS 'Email of the helper assigned to this job (for private jobs)';
COMMENT ON COLUMN jobs.helper_selection_method IS 'Method used to select helper: search, direct, or application';
COMMENT ON FUNCTION get_private_jobs_for_helper_enhanced(UUID) IS 'Enhanced function to get private jobs for a specific helper';
COMMENT ON FUNCTION get_assigned_private_jobs(UUID) IS 'Get private jobs assigned to a helper with full details';
COMMENT ON FUNCTION assign_helper_to_job(UUID, UUID, VARCHAR) IS 'Assign a helper to a job';
COMMENT ON FUNCTION create_private_job_notification(UUID, UUID, VARCHAR, UUID) IS 'Create notification for private job assignment'; 