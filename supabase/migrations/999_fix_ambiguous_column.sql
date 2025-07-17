-- Fix the ambiguous column reference in get_assigned_private_jobs function

-- Drop the problematic function
DROP FUNCTION IF EXISTS get_assigned_private_jobs(UUID);

-- Create a fixed version with explicit column references
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
  category_data JSON,
  is_private BOOLEAN
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
    to_json(category.*) as category_data,
    j.is_private
  FROM jobs j
  LEFT JOIN users helpee ON j.helpee_id = helpee.id
  LEFT JOIN job_categories category ON j.category_id = category.id
  WHERE (
    j.assigned_helper_id = helper_user_id OR 
    j.invited_helper_email = (SELECT email FROM users WHERE id = helper_user_id) OR
    j.assigned_helper_email = (SELECT email FROM users WHERE id = helper_user_id)
  )
  AND j.is_private = true
  AND j.status IN ('pending', 'accepted')
  ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql; 