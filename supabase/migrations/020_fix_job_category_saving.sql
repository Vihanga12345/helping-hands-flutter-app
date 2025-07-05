-- HELPING HANDS APP - Fix Job Category Saving
-- ============================================================================
-- Migration 020: Fix job category saving and ensure proper referential integrity
-- Date: January 2025
-- Purpose: Fix job category not being saved properly to database

-- ============================================================================
-- STEP 1: Verify job_categories table structure and data
-- ============================================================================

-- Ensure job_categories table has proper UUID structure
ALTER TABLE job_categories ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Add missing job categories if they don't exist
INSERT INTO job_categories (name, description, default_hourly_rate, is_active) VALUES
('House Cleaning', 'General house cleaning services', 2500.00, true),
('Deep Cleaning', 'Thorough deep cleaning services', 3000.00, true),
('Gardening', 'Garden maintenance and landscaping', 2000.00, true),
('Cooking', 'Meal preparation and cooking services', 2200.00, true),
('Elderly Care', 'Care and assistance for elderly', 2800.00, true),
('Child Care', 'Childcare and babysitting services', 2400.00, true),
('Pet Care', 'Pet sitting and care services', 1800.00, true),
('Tutoring', 'Educational tutoring services', 3500.00, true),
('Tech Support', 'Technology assistance and support', 4000.00, true),
('Moving Help', 'Moving and relocation assistance', 2800.00, true),
('Plumbing', 'Plumbing repair and installation', 3500.00, true),
('Electrical Work', 'Electrical repair and installation', 4000.00, true),
('Painting', 'Painting and decoration services', 2500.00, true),
('Furniture Assembly', 'Furniture assembly and installation', 2000.00, true),
('Car Washing', 'Vehicle cleaning and maintenance', 1500.00, true),
('Delivery Services', 'Package and item delivery', 1800.00, true),
('Event Planning', 'Event organization and planning', 3000.00, true),
('Shopping Assistance', 'Shopping and errands assistance', 2000.00, true),
('Office Maintenance', 'Office cleaning and maintenance', 2200.00, true),
('Photography', 'Photography and videography services', 4000.00, true)
ON CONFLICT (name) DO UPDATE SET
    default_hourly_rate = EXCLUDED.default_hourly_rate,
    is_active = EXCLUDED.is_active;

-- ============================================================================
-- STEP 2: Verify jobs table structure
-- ============================================================================

-- Ensure category_id column exists and has proper foreign key constraint
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS category_id UUID;

-- Add updated_at column to jobs table if it doesn't exist
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Add updated_at column to job_categories table if it doesn't exist
ALTER TABLE job_categories ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Drop and recreate foreign key constraint to ensure it's working
ALTER TABLE jobs DROP CONSTRAINT IF EXISTS jobs_category_id_fkey;
ALTER TABLE jobs ADD CONSTRAINT jobs_category_id_fkey 
    FOREIGN KEY (category_id) REFERENCES job_categories(id) ON DELETE RESTRICT;

-- Ensure is_private column exists and is properly set based on job_type
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;

-- Update is_private based on job_type where it's null
UPDATE jobs SET is_private = (job_type = 'private') WHERE is_private IS NULL;

-- ============================================================================
-- STEP 3: Fix create_job_with_helpee_details function
-- ============================================================================

-- Recreate the function with better error handling and logging
CREATE OR REPLACE FUNCTION create_job_with_helpee_details(
    p_helpee_id UUID,
    p_category_id UUID,
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
    category_exists BOOLEAN;
BEGIN
    -- Verify that the category exists
    SELECT EXISTS(SELECT 1 FROM job_categories WHERE id = p_category_id AND is_active = true) 
    INTO category_exists;
    
    IF NOT category_exists THEN
        RAISE EXCEPTION 'Invalid or inactive job category: %', p_category_id;
    END IF;
    
    -- Log the operation (for debugging)
    RAISE NOTICE 'Creating job with category_id: %, job_type: %, title: %', p_category_id, p_job_type, p_title;
    
    -- Insert the job
    INSERT INTO jobs (
        helpee_id, 
        category_id, 
        title, 
        description, 
        job_type,
        hourly_rate, 
        scheduled_date, 
        scheduled_start_time, 
        scheduled_time,
        location_latitude, 
        location_longitude, 
        location_address,
        is_private,
        status
    ) VALUES (
        p_helpee_id, 
        p_category_id, 
        p_title, 
        p_description, 
        p_job_type,
        p_hourly_rate, 
        p_scheduled_date, 
        p_scheduled_start_time, 
        p_scheduled_start_time,
        p_location_latitude, 
        p_location_longitude, 
        p_location_address,
        (p_job_type = 'private'),
        'pending'
    ) RETURNING id INTO new_job_id;
    
    -- Log successful creation
    RAISE NOTICE 'Successfully created job with ID: %, category_id: %', new_job_id, p_category_id;
    
    RETURN new_job_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 4: Create validation trigger for jobs
-- ============================================================================

-- Function to validate job data before insert/update
CREATE OR REPLACE FUNCTION validate_job_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure category_id is not null
    IF NEW.category_id IS NULL THEN
        RAISE EXCEPTION 'Job category_id cannot be null';
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
    
    -- Update updated_at if column exists
    BEGIN
        NEW.updated_at = NOW();
    EXCEPTION WHEN undefined_column THEN
        -- Column does not exist, continue without error
        NULL;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for job validation
DROP TRIGGER IF EXISTS validate_job_data_trigger ON jobs;
CREATE TRIGGER validate_job_data_trigger
    BEFORE INSERT OR UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION validate_job_data();

-- Fix the general update_updated_at_column function to handle missing columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    -- Try to update updated_at and handle errors gracefully
    BEGIN
        NEW.updated_at = NOW();
    EXCEPTION WHEN undefined_column THEN
        -- Column does not exist, continue without error
        NULL;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 5: Create helper function to debug job categories
-- ============================================================================

-- Function to get job category info for debugging
CREATE OR REPLACE FUNCTION get_job_category_info(p_job_id UUID)
RETURNS TABLE (
    job_id UUID,
    category_id UUID,
    category_name VARCHAR(100),
    job_title VARCHAR(200),
    job_type VARCHAR(20),
    is_private BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        j.id,
        j.category_id,
        jc.name,
        j.title,
        j.job_type,
        j.is_private
    FROM jobs j
    LEFT JOIN job_categories jc ON j.category_id = jc.id
    WHERE j.id = p_job_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 6: Fix any existing jobs with missing category_id
-- ============================================================================

-- Update jobs with null category_id to use a default category
DO $$
DECLARE
    default_category_id UUID;
BEGIN
    -- Get the ID of 'House Cleaning' category as default
    SELECT id INTO default_category_id 
    FROM job_categories 
    WHERE name = 'House Cleaning' 
    LIMIT 1;
    
    IF default_category_id IS NOT NULL THEN
        -- Update jobs with missing category_id
        UPDATE jobs 
        SET category_id = default_category_id 
        WHERE category_id IS NULL;
        
        RAISE NOTICE 'Updated % jobs with missing category_id', 
                     (SELECT COUNT(*) FROM jobs WHERE category_id = default_category_id);
    END IF;
END $$;

-- ============================================================================
-- STEP 7: Create indexes for performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_jobs_category_id ON jobs(category_id);
CREATE INDEX IF NOT EXISTS idx_jobs_category_status ON jobs(category_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_is_private_status ON jobs(is_private, status);

-- ============================================================================
-- STEP 8: Add updated_at triggers
-- ============================================================================

-- Add updated_at triggers for tables that have the column
DROP TRIGGER IF EXISTS update_jobs_updated_at ON jobs;
CREATE TRIGGER update_jobs_updated_at
    BEFORE UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_job_categories_updated_at ON job_categories;
CREATE TRIGGER update_job_categories_updated_at
    BEFORE UPDATE ON job_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
    -- Verify job_categories table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'job_categories') THEN
        RAISE NOTICE '✅ job_categories table exists with % categories', 
                     (SELECT COUNT(*) FROM job_categories WHERE is_active = true);
    ELSE
        RAISE EXCEPTION '❌ job_categories table missing';
    END IF;
    
    -- Verify foreign key constraint
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'jobs_category_id_fkey' 
               AND table_name = 'jobs') THEN
        RAISE NOTICE '✅ jobs.category_id foreign key constraint exists';
    ELSE
        RAISE EXCEPTION '❌ jobs.category_id foreign key constraint missing';
    END IF;
    
    -- Verify function exists
    IF EXISTS (SELECT 1 FROM information_schema.routines 
               WHERE routine_name = 'create_job_with_helpee_details') THEN
        RAISE NOTICE '✅ create_job_with_helpee_details function exists';
    ELSE
        RAISE EXCEPTION '❌ create_job_with_helpee_details function missing';
    END IF;
    
    RAISE NOTICE '🎉 Migration 020_fix_job_category_saving completed successfully!';
END $$; 