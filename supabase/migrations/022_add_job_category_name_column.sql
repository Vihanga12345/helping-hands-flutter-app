-- HELPING HANDS APP - Add Job Category Name Column
-- ============================================================================
-- Migration 022: Add job_category_name column to jobs table for better filtering
-- Date: January 2025
-- Purpose: Store job category names directly in jobs table for simplified helper filtering

-- ============================================================================
-- STEP 1: Add job_category_name column to jobs table
-- ============================================================================

-- Add the new column to store job category names like "Gardening", "Deep Cleaning", etc.
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS job_category_name VARCHAR(100);

-- Create index for faster filtering
CREATE INDEX IF NOT EXISTS idx_jobs_category_name ON jobs(job_category_name);

-- ============================================================================
-- STEP 2: Update existing jobs with category names from job_categories table
-- ============================================================================

-- Update existing jobs to have category names
UPDATE jobs 
SET job_category_name = job_categories.name
FROM job_categories 
WHERE jobs.category_id = job_categories.id 
AND jobs.job_category_name IS NULL;

-- ============================================================================
-- STEP 3: Update the job creation function to handle category name
-- ============================================================================

CREATE OR REPLACE FUNCTION create_job_with_helpee_details(
    p_helpee_id UUID,
    p_category_id UUID,
    p_job_category_name VARCHAR(100),
    p_title VARCHAR(200),
    p_description TEXT,
    p_job_type VARCHAR(20),
    p_hourly_rate DECIMAL(10, 2),
    p_scheduled_date DATE,
    p_scheduled_start_time TIME,
    p_location_latitude DECIMAL(10, 8),
    p_location_longitude DECIMAL(11, 8),
    p_location_address TEXT
) RETURNS UUID AS $$
DECLARE
    new_job_id UUID;
    is_private_job BOOLEAN;
BEGIN
    -- Determine if job is private
    is_private_job := (p_job_type = 'private');
    
    -- Create the job record
    INSERT INTO jobs (
        helpee_id,
        category_id,
        job_category_name,
        title,
        description,
        job_type,
        is_private,
        hourly_rate,
        scheduled_date,
        scheduled_start_time,
        location_latitude,
        location_longitude,
        location_address,
        status
    ) VALUES (
        p_helpee_id,
        p_category_id,
        p_job_category_name,
        p_title,
        p_description,
        p_job_type,
        is_private_job,
        p_hourly_rate,
        p_scheduled_date,
        p_scheduled_start_time,
        p_location_latitude,
        p_location_longitude,
        p_location_address,
        'pending'
    ) RETURNING id INTO new_job_id;
    
    RETURN new_job_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 4: Create simplified helper job filtering functions
-- ============================================================================

-- Function to get public jobs filtered by category name
CREATE OR REPLACE FUNCTION get_public_jobs_by_category(p_category_names TEXT[])
RETURNS TABLE (
    id UUID,
    title VARCHAR(200),
    description TEXT,
    job_category_name VARCHAR(100),
    hourly_rate DECIMAL(10, 2),
    scheduled_date DATE,
    scheduled_start_time TIME,
    location_address TEXT,
    status VARCHAR(50),
    created_at TIMESTAMP,
    helpee_first_name VARCHAR(100),
    helpee_last_name VARCHAR(100),
    helpee_location_city VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        j.id,
        j.title,
        j.description,
        j.job_category_name,
        j.hourly_rate,
        j.scheduled_date,
        j.scheduled_start_time,
        j.location_address,
        j.status,
        j.created_at,
        u.first_name,
        u.last_name,
        u.location_city
    FROM jobs j
    JOIN users u ON j.helpee_id = u.id
    WHERE j.is_private = false
    AND j.status = 'pending'
    AND j.assigned_helper_id IS NULL
    AND j.job_category_name = ANY(p_category_names)
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get private jobs for a specific helper filtered by category name
CREATE OR REPLACE FUNCTION get_private_jobs_for_helper_by_category(
    p_helper_id UUID,
    p_category_names TEXT[]
)
RETURNS TABLE (
    id UUID,
    title VARCHAR(200),
    description TEXT,
    job_category_name VARCHAR(100),
    hourly_rate DECIMAL(10, 2),
    scheduled_date DATE,
    scheduled_start_time TIME,
    location_address TEXT,
    status VARCHAR(50),
    created_at TIMESTAMP,
    helpee_first_name VARCHAR(100),
    helpee_last_name VARCHAR(100),
    helpee_location_city VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        j.id,
        j.title,
        j.description,
        j.job_category_name,
        j.hourly_rate,
        j.scheduled_date,
        j.scheduled_start_time,
        j.location_address,
        j.status,
        j.created_at,
        u.first_name,
        u.last_name,
        u.location_city
    FROM jobs j
    JOIN users u ON j.helpee_id = u.id
    WHERE j.is_private = true
    AND j.assigned_helper_id = p_helper_id
    AND j.status = 'pending'
    AND j.job_category_name = ANY(p_category_names)
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 5: Update the job validation trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_job_data_with_category_name()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure category_id is not null
    IF NEW.category_id IS NULL THEN
        RAISE EXCEPTION 'Job category_id cannot be null';
    END IF;
    
    -- Ensure job_category_name is not null
    IF NEW.job_category_name IS NULL OR NEW.job_category_name = '' THEN
        RAISE EXCEPTION 'Job category_name cannot be null or empty';
    END IF;
    
    -- Ensure category exists and is active
    IF NOT EXISTS(SELECT 1 FROM job_categories WHERE id = NEW.category_id AND is_active = true) THEN
        RAISE EXCEPTION 'Invalid or inactive job category: %', NEW.category_id;
    END IF;
    
    -- Sync is_private with job_type
    IF NEW.job_type = 'private' THEN
        NEW.is_private = true;
    ELSE
        NEW.is_private = false;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Replace the old trigger
DROP TRIGGER IF EXISTS validate_job_data_simple_trigger ON jobs;
CREATE TRIGGER validate_job_data_with_category_name_trigger
    BEFORE INSERT OR UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION validate_job_data_with_category_name();

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if job_category_name column was added
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'jobs'
    AND column_name = 'job_category_name';

-- Check sample data
SELECT 
    id,
    title,
    job_type,
    job_category_name,
    category_id,
    created_at
FROM jobs 
ORDER BY created_at DESC 
LIMIT 5;

COMMIT; 