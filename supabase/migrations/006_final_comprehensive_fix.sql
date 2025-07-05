-- HELPING HANDS APP - COMPREHENSIVE FINAL FIX
-- ============================================================================
-- This migration fixes all database issues while being compatible with existing schemas
-- Run this file AFTER running the base schema files

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- STEP 1: Add missing columns to jobs table that are referenced in the app
-- ============================================================================

-- Add rating columns if they don't exist (from 001_complete_schema.sql)
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helpee_rating INTEGER CHECK (helpee_rating >= 1 AND helpee_rating <= 5);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helper_rating INTEGER CHECK (helper_rating >= 1 AND helper_rating <= 5);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helpee_review TEXT;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helper_review TEXT;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10, 2);

-- Add scheduled_time column (app expects this)
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS scheduled_time TIME;

-- Update existing records to copy scheduled_start_time to scheduled_time
UPDATE jobs SET scheduled_time = scheduled_start_time WHERE scheduled_time IS NULL;

-- Add is_private column (app uses this instead of job_type)
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;

-- Update is_private based on job_type
UPDATE jobs SET is_private = (job_type = 'private') WHERE is_private IS NULL OR (job_type = 'private' AND is_private = false);

-- Add missing timestamp columns that the app references
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS started_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS paused_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS resumed_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;

-- Add rating tracking columns (from 001_initial_schema.sql)
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS is_rated_by_helpee BOOLEAN DEFAULT FALSE;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS is_rated_by_helper BOOLEAN DEFAULT FALSE;

-- ============================================================================
-- STEP 2: Update job status values to match app expectations
-- ============================================================================

-- Remove existing constraint and add new one with all expected statuses
ALTER TABLE jobs DROP CONSTRAINT IF EXISTS jobs_status_check;
ALTER TABLE jobs ADD CONSTRAINT jobs_status_check 
    CHECK (status IN ('pending', 'accepted', 'started', 'in_progress', 'paused', 'completed', 'cancelled', 'rejected'));

-- Update existing records to use 'started' instead of 'in_progress'
UPDATE jobs SET status = 'started' WHERE status = 'in_progress';

-- ============================================================================
-- STEP 3: Add missing columns to users table
-- ============================================================================

-- Add columns that might be missing
ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(50) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(20) DEFAULT 'English';
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_currency VARCHAR(10) DEFAULT 'LKR';
ALTER TABLE users ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_completion_percentage INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS hourly_rate_default DECIMAL(10,2) DEFAULT 2000.00;
ALTER TABLE users ADD COLUMN IF NOT EXISTS availability_status VARCHAR(20) DEFAULT 'available';
ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_status VARCHAR(20) DEFAULT 'pending';

-- Update display_name if it's null
UPDATE users SET display_name = first_name || ' ' || last_name WHERE display_name IS NULL;

-- ============================================================================
-- STEP 4: Ensure job_reports table structure is compatible
-- ============================================================================

-- Add missing columns to existing job_reports table
-- (works with existing structure from 001_initial_schema.sql)
ALTER TABLE job_reports ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- ============================================================================
-- STEP 5: Create statistics views (compatible with actual table structure)
-- ============================================================================

-- Drop existing views if they exist
DROP VIEW IF EXISTS helpee_statistics;
DROP VIEW IF EXISTS helper_statistics;

-- Create helpee_statistics view
CREATE OR REPLACE VIEW helpee_statistics AS
SELECT 
    u.id as helpee_id,
    u.first_name,
    u.last_name,
    COALESCE(u.display_name, u.first_name || ' ' || u.last_name) as display_name,
    u.created_at as member_since,
    COUNT(j.id) as total_jobs,
    COUNT(CASE WHEN j.status = 'pending' THEN 1 END) as pending_jobs,
    COUNT(CASE WHEN j.status IN ('started', 'accepted') THEN 1 END) as ongoing_jobs,
    COUNT(CASE WHEN j.status = 'completed' THEN 1 END) as completed_jobs,
    COUNT(CASE WHEN j.status = 'cancelled' THEN 1 END) as cancelled_jobs,
    COALESCE(AVG(CASE WHEN j.helper_rating IS NOT NULL THEN j.helper_rating END), 0) as average_rating_given,
    COALESCE(SUM(CASE WHEN j.total_amount IS NOT NULL THEN j.total_amount END), 0) as total_spent
FROM users u
LEFT JOIN jobs j ON u.id = j.helpee_id
WHERE u.user_type = 'helpee'
GROUP BY u.id, u.first_name, u.last_name, u.display_name, u.created_at;

-- Create helper_statistics view
CREATE OR REPLACE VIEW helper_statistics AS
SELECT 
    u.id as helper_id,
    u.first_name,
    u.last_name,
    COALESCE(u.display_name, u.first_name || ' ' || u.last_name) as display_name,
    u.created_at as member_since,
    COUNT(j.id) as total_jobs,
    COUNT(CASE WHEN j.status = 'pending' THEN 1 END) as pending_jobs,
    COUNT(CASE WHEN j.status = 'accepted' THEN 1 END) as accepted_jobs,
    COUNT(CASE WHEN j.status IN ('started', 'in_progress') THEN 1 END) as ongoing_jobs,
    COUNT(CASE WHEN j.status = 'completed' THEN 1 END) as completed_jobs,
    COUNT(CASE WHEN j.status = 'cancelled' THEN 1 END) as cancelled_jobs,
    COALESCE(AVG(CASE WHEN j.helpee_rating IS NOT NULL THEN j.helpee_rating END), 0) as average_rating_received,
    COALESCE(SUM(CASE WHEN j.total_amount IS NOT NULL THEN j.total_amount END), 0) as total_earned
FROM users u
LEFT JOIN jobs j ON u.id = j.assigned_helper_id
WHERE u.user_type = 'helper'
GROUP BY u.id, u.first_name, u.last_name, u.display_name, u.created_at;

-- ============================================================================
-- STEP 6: Create/Update required functions
-- ============================================================================

-- Function to sync scheduled_time with scheduled_start_time
CREATE OR REPLACE FUNCTION sync_scheduled_time()
RETURNS TRIGGER AS $$
BEGIN
    -- When scheduled_start_time is updated, update scheduled_time too
    IF NEW.scheduled_start_time IS DISTINCT FROM OLD.scheduled_start_time THEN
        NEW.scheduled_time = NEW.scheduled_start_time;
    END IF;
    
    -- When scheduled_time is updated, update scheduled_start_time too
    IF NEW.scheduled_time IS DISTINCT FROM OLD.scheduled_time THEN
        NEW.scheduled_start_time = NEW.scheduled_time;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for scheduled_time sync
DROP TRIGGER IF EXISTS sync_scheduled_time_trigger ON jobs;
CREATE TRIGGER sync_scheduled_time_trigger 
    BEFORE UPDATE ON jobs 
    FOR EACH ROW 
    EXECUTE FUNCTION sync_scheduled_time();

-- Ensure create_job_with_helpee_details function exists
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
BEGIN
    INSERT INTO jobs (
        helpee_id, category_id, title, description, job_type,
        hourly_rate, scheduled_date, scheduled_start_time, scheduled_time,
        location_latitude, location_longitude, location_address,
        is_private
    ) VALUES (
        p_helpee_id, p_category_id, p_title, p_description, p_job_type,
        p_hourly_rate, p_scheduled_date, p_scheduled_start_time, p_scheduled_start_time,
        p_location_latitude, p_location_longitude, p_location_address,
        (p_job_type = 'private')
    ) RETURNING id INTO new_job_id;
    
    RETURN new_job_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 7: Create indexes for performance
-- ============================================================================

-- Indexes for jobs table
CREATE INDEX IF NOT EXISTS idx_jobs_is_private ON jobs(is_private);
CREATE INDEX IF NOT EXISTS idx_jobs_scheduled_time ON jobs(scheduled_time);
CREATE INDEX IF NOT EXISTS idx_jobs_helpee_status ON jobs(helpee_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_helper_status ON jobs(assigned_helper_id, status);

-- Indexes for job_reports table (using existing column names from 001_initial_schema.sql)
CREATE INDEX IF NOT EXISTS idx_job_reports_job_id ON job_reports(job_id);
CREATE INDEX IF NOT EXISTS idx_job_reports_reporter_id ON job_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_job_reports_status ON job_reports(status);

-- ============================================================================
-- STEP 8: Update triggers for updated_at columns
-- ============================================================================

-- Ensure update_updated_at_column function exists
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add trigger for job_reports updated_at
DROP TRIGGER IF EXISTS update_job_reports_updated_at ON job_reports;
CREATE TRIGGER update_job_reports_updated_at 
    BEFORE UPDATE ON job_reports 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- FINAL NOTES
-- ============================================================================

-- This migration is now compatible with existing schema from 001_initial_schema.sql
-- It adds missing columns and creates views that work with the actual table structure
-- Uses existing column names like 'reporter_id' instead of 'reported_by'
-- All functions and triggers are created/updated to handle the current schema 