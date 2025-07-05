-- ============================================================================
-- PRODUCTION DATABASE FIX SCRIPT
-- ============================================================================
-- Execute this script in your Supabase SQL Editor to fix job category filtering
-- Date: January 2025

-- ============================================================================
-- STEP 1: Add job_category_name column to jobs table
-- ============================================================================

-- Add the new column to store job category names like "Baby Care", "Gardening", etc.
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS job_category_name VARCHAR(100);

-- Create index for faster filtering
CREATE INDEX IF NOT EXISTS idx_jobs_category_name ON jobs(job_category_name);

-- ============================================================================
-- STEP 2: Update existing jobs with category names
-- ============================================================================

-- Update existing jobs to have category names from job_categories table
UPDATE jobs 
SET job_category_name = job_categories.name
FROM job_categories 
WHERE jobs.category_id = job_categories.id 
AND jobs.job_category_name IS NULL;

-- ============================================================================
-- STEP 3: Update job creation function to handle category name
-- ============================================================================

-- Drop existing function to avoid conflicts
DROP FUNCTION IF EXISTS create_job_with_helpee_details(UUID, UUID, VARCHAR, TEXT, VARCHAR, DECIMAL, DATE, TIME, DECIMAL, DECIMAL, TEXT);
DROP FUNCTION IF EXISTS create_job_with_helpee_details(UUID, UUID, VARCHAR, VARCHAR, TEXT, VARCHAR, DECIMAL, DATE, TIME, DECIMAL, DECIMAL, TEXT);

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
-- STEP 4: Create helper filtering functions using category names
-- ============================================================================

-- First, drop existing functions if they exist (to avoid return type conflicts)
DROP FUNCTION IF EXISTS get_helper_job_categories(UUID);
DROP FUNCTION IF EXISTS get_public_jobs_for_helper(UUID);
DROP FUNCTION IF EXISTS get_private_jobs_for_helper(UUID);
DROP FUNCTION IF EXISTS get_public_jobs_by_category(TEXT[]);
DROP FUNCTION IF EXISTS get_private_jobs_for_helper_by_category(UUID, TEXT[]);

-- Function to get helper's preferred job category names
CREATE OR REPLACE FUNCTION get_helper_job_categories(p_helper_id UUID)
RETURNS TEXT[] AS $$
DECLARE
    category_names TEXT[];
BEGIN
    SELECT ARRAY_AGG(jc.name)
    INTO category_names
    FROM helper_job_types hjt
    JOIN job_categories jc ON hjt.job_category_id = jc.id
    WHERE hjt.helper_id = p_helper_id;
    
    RETURN COALESCE(category_names, ARRAY[]::TEXT[]);
END;
$$ LANGUAGE plpgsql;

-- Function to get public jobs filtered by helper's preferences
CREATE OR REPLACE FUNCTION get_public_jobs_for_helper(p_helper_id UUID)
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
    created_at TIMESTAMP WITH TIME ZONE,
    helpee_first_name VARCHAR(100),
    helpee_last_name VARCHAR(100),
    helpee_location_city VARCHAR(100)
) AS $$
DECLARE
    helper_categories TEXT[];
BEGIN
    -- Get helper's preferred job categories
    SELECT get_helper_job_categories(p_helper_id) INTO helper_categories;
    
    -- Return empty if helper has no preferences
    IF array_length(helper_categories, 1) IS NULL THEN
        RETURN;
    END IF;
    
    -- Return filtered public jobs
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
    AND j.job_category_name = ANY(helper_categories)
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get private jobs for helper
CREATE OR REPLACE FUNCTION get_private_jobs_for_helper(p_helper_id UUID)
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
    created_at TIMESTAMP WITH TIME ZONE,
    helpee_first_name VARCHAR(100),
    helpee_last_name VARCHAR(100),
    helpee_location_city VARCHAR(100)
) AS $$
DECLARE
    helper_categories TEXT[];
BEGIN
    -- Get helper's preferred job categories
    SELECT get_helper_job_categories(p_helper_id) INTO helper_categories;
    
    -- Return empty if helper has no preferences
    IF array_length(helper_categories, 1) IS NULL THEN
        RETURN;
    END IF;
    
    -- Return filtered private jobs
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
    AND j.job_category_name = ANY(helper_categories)
    ORDER BY j.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 5: Create trigger to auto-populate job_category_name
-- ============================================================================

-- Drop existing function and trigger to avoid conflicts
DROP TRIGGER IF EXISTS auto_populate_job_category_name_trigger ON jobs;
DROP FUNCTION IF EXISTS auto_populate_job_category_name();

CREATE OR REPLACE FUNCTION auto_populate_job_category_name()
RETURNS TRIGGER AS $$
BEGIN
    -- If job_category_name is not provided, get it from job_categories table
    IF NEW.job_category_name IS NULL OR NEW.job_category_name = '' THEN
        SELECT name INTO NEW.job_category_name
        FROM job_categories
        WHERE id = NEW.category_id;
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

-- Create trigger
DROP TRIGGER IF EXISTS auto_populate_job_category_name_trigger ON jobs;
CREATE TRIGGER auto_populate_job_category_name_trigger
    BEFORE INSERT OR UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION auto_populate_job_category_name();

-- ============================================================================
-- STEP 6: Verification queries
-- ============================================================================

-- Check if job_category_name column was added and populated
SELECT 
    COUNT(*) as total_jobs,
    COUNT(job_category_name) as jobs_with_category_name,
    COUNT(CASE WHEN job_category_name IS NULL OR job_category_name = '' THEN 1 END) as jobs_without_category_name
FROM jobs;

-- Show sample job data
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

-- Check helper preferences
SELECT 
    u.first_name,
    u.last_name,
    ARRAY_AGG(jc.name) as preferred_categories
FROM users u
JOIN helper_job_types hjt ON u.id = hjt.helper_id
JOIN job_categories jc ON hjt.job_category_id = jc.id
WHERE u.user_type = 'helper'
GROUP BY u.id, u.first_name, u.last_name
ORDER BY u.first_name;

-- Test helper filtering (replace 'HELPER_ID_HERE' with actual helper ID)
-- SELECT * FROM get_public_jobs_for_helper('HELPER_ID_HERE');

COMMIT; 