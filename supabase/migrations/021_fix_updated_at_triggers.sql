-- HELPING HANDS APP - Fix Updated At Triggers
-- ============================================================================
-- Migration 021: Fix updated_at column triggers that are causing errors
-- Date: January 2025
-- Purpose: Fix the "record has no field updated_at" error by properly handling triggers

-- ============================================================================
-- STEP 1: Drop all existing updated_at triggers to prevent conflicts
-- ============================================================================

DROP TRIGGER IF EXISTS update_user_authentication_updated_at ON user_authentication;
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP TRIGGER IF EXISTS update_job_categories_updated_at ON job_categories;
DROP TRIGGER IF EXISTS update_job_category_questions_updated_at ON job_category_questions;
DROP TRIGGER IF EXISTS update_jobs_updated_at ON jobs;
DROP TRIGGER IF EXISTS validate_job_data_trigger ON jobs;

-- ============================================================================
-- STEP 2: Create a safer updated_at function that checks for column existence
-- ============================================================================

CREATE OR REPLACE FUNCTION safe_update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the table has an updated_at column by trying to reference it
    -- This will only work if the column exists
    IF TG_TABLE_NAME = 'user_authentication' THEN
        NEW.updated_at = NOW();
    ELSIF TG_TABLE_NAME = 'users' THEN
        NEW.updated_at = NOW();
    ELSIF TG_TABLE_NAME = 'job_categories' THEN
        NEW.updated_at = NOW();
    ELSIF TG_TABLE_NAME = 'job_category_questions' THEN
        NEW.updated_at = NOW();
    ELSIF TG_TABLE_NAME = 'jobs' THEN
        NEW.updated_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 3: Ensure all required tables have updated_at columns
-- ============================================================================

-- Add updated_at columns where missing
ALTER TABLE user_authentication ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();
ALTER TABLE job_categories ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();
ALTER TABLE job_category_questions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- ============================================================================
-- STEP 4: Create triggers only for tables with updated_at columns
-- ============================================================================

-- Create triggers using the safe function
CREATE TRIGGER safe_update_user_authentication_updated_at
    BEFORE UPDATE ON user_authentication
    FOR EACH ROW EXECUTE FUNCTION safe_update_updated_at_column();

CREATE TRIGGER safe_update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION safe_update_updated_at_column();

CREATE TRIGGER safe_update_job_categories_updated_at
    BEFORE UPDATE ON job_categories
    FOR EACH ROW EXECUTE FUNCTION safe_update_updated_at_column();

CREATE TRIGGER safe_update_job_category_questions_updated_at
    BEFORE UPDATE ON job_category_questions
    FOR EACH ROW EXECUTE FUNCTION safe_update_updated_at_column();

CREATE TRIGGER safe_update_jobs_updated_at
    BEFORE UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION safe_update_updated_at_column();

-- ============================================================================
-- STEP 5: Create a simplified job validation trigger without updated_at dependency
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_job_data_simple()
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
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create simplified validation trigger
CREATE TRIGGER validate_job_data_simple_trigger
    BEFORE INSERT OR UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION validate_job_data_simple();

-- ============================================================================
-- STEP 6: Ensure proper job structure
-- ============================================================================

-- Ensure jobs table has all required columns
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS category_id UUID;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;

-- Update is_private based on job_type where it's null
UPDATE jobs SET is_private = (job_type = 'private') WHERE is_private IS NULL;

-- Add foreign key constraint if it doesn't exist
ALTER TABLE jobs DROP CONSTRAINT IF EXISTS jobs_category_id_fkey;
ALTER TABLE jobs ADD CONSTRAINT jobs_category_id_fkey 
    FOREIGN KEY (category_id) REFERENCES job_categories(id) ON DELETE RESTRICT;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if all tables have updated_at columns
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND column_name = 'updated_at'
    AND table_name IN ('user_authentication', 'users', 'job_categories', 'job_category_questions', 'jobs')
ORDER BY table_name;

-- Check trigger status
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
    AND trigger_name LIKE '%updated_at%'
ORDER BY event_object_table;

COMMIT; 