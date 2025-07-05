-- HELPING HANDS APP - FIX DATABASE ISSUES
-- ============================================================================
-- This migration fixes the database issues found during app testing:
-- 1. Add scheduled_time column (alias for scheduled_start_time)
-- 2. Create missing helpee_statistics view
-- 3. Create helper_statistics view
-- 4. Fix column references and missing tables

-- ============================================================================
-- Add missing columns to jobs table FIRST
-- ============================================================================

-- Add rating columns if they don't exist
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helpee_rating INTEGER CHECK (helpee_rating >= 1 AND helpee_rating <= 5);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helper_rating INTEGER CHECK (helper_rating >= 1 AND helper_rating <= 5);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helpee_review TEXT;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helper_review TEXT;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10, 2);

-- ============================================================================
-- Fix scheduled_time column issue
-- ============================================================================

-- Add scheduled_time as a computed column (alias for scheduled_start_time)
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS scheduled_time TIME;

-- Update existing records to copy scheduled_start_time to scheduled_time
UPDATE jobs SET scheduled_time = scheduled_start_time WHERE scheduled_time IS NULL;

-- Create trigger to keep scheduled_time in sync with scheduled_start_time
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

DROP TRIGGER IF EXISTS sync_scheduled_time_trigger ON jobs;
CREATE TRIGGER sync_scheduled_time_trigger 
    BEFORE UPDATE ON jobs 
    FOR EACH ROW 
    EXECUTE FUNCTION sync_scheduled_time();

-- ============================================================================
-- Create helpee_statistics view
-- ============================================================================

CREATE OR REPLACE VIEW helpee_statistics AS
SELECT 
    u.id as helpee_id,
    u.first_name,
    u.last_name,
    COUNT(j.id) as total_jobs,
    COUNT(CASE WHEN j.status = 'pending' THEN 1 END) as pending_jobs,
    COUNT(CASE WHEN j.status IN ('started', 'in_progress') THEN 1 END) as ongoing_jobs,
    COUNT(CASE WHEN j.status = 'completed' THEN 1 END) as completed_jobs,
    COUNT(CASE WHEN j.status = 'cancelled' THEN 1 END) as cancelled_jobs,
    COALESCE(AVG(j.helper_rating), 0) as average_rating_given,
    COALESCE(SUM(j.total_amount), 0) as total_spent
FROM users u
LEFT JOIN jobs j ON u.id = j.helpee_id
WHERE u.user_type = 'helpee'
GROUP BY u.id, u.first_name, u.last_name;

-- ============================================================================
-- Create helper_statistics view
-- ============================================================================

CREATE OR REPLACE VIEW helper_statistics AS
SELECT 
    u.id as helper_id,
    u.first_name,
    u.last_name,
    COUNT(j.id) as total_jobs,
    COUNT(CASE WHEN j.status = 'pending' THEN 1 END) as pending_jobs,
    COUNT(CASE WHEN j.status = 'accepted' THEN 1 END) as accepted_jobs,
    COUNT(CASE WHEN j.status IN ('started', 'in_progress') THEN 1 END) as ongoing_jobs,
    COUNT(CASE WHEN j.status = 'completed' THEN 1 END) as completed_jobs,
    COUNT(CASE WHEN j.status = 'cancelled' THEN 1 END) as cancelled_jobs,
    COALESCE(AVG(j.helpee_rating), 0) as average_rating_received,
    COALESCE(SUM(j.total_amount), 0) as total_earned
FROM users u
LEFT JOIN jobs j ON u.id = j.assigned_helper_id
WHERE u.user_type = 'helper'
GROUP BY u.id, u.first_name, u.last_name;

-- ============================================================================
-- Create job_reports table (referenced in JobDataService)
-- ============================================================================

CREATE TABLE IF NOT EXISTS job_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    reported_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reported_against UUID REFERENCES users(id) ON DELETE SET NULL,
    reason VARCHAR(100) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
    admin_notes TEXT,
    resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for job_reports
CREATE INDEX IF NOT EXISTS idx_job_reports_job_id ON job_reports(job_id);
CREATE INDEX IF NOT EXISTS idx_job_reports_reported_by ON job_reports(reported_by);
CREATE INDEX IF NOT EXISTS idx_job_reports_status ON job_reports(status);

-- ============================================================================
-- Update job status values to match code expectations  
-- ============================================================================

-- Update status values to match what the app expects
-- The app uses: pending, accepted, started, paused, completed, cancelled, rejected
-- Database schema has: pending, accepted, in_progress, paused, completed, cancelled, rejected

-- Add new status values if they don't exist
ALTER TABLE jobs DROP CONSTRAINT IF EXISTS jobs_status_check;
ALTER TABLE jobs ADD CONSTRAINT jobs_status_check 
    CHECK (status IN ('pending', 'accepted', 'started', 'in_progress', 'paused', 'completed', 'cancelled', 'rejected'));

-- Update existing records to use 'started' instead of 'in_progress'
UPDATE jobs SET status = 'started' WHERE status = 'in_progress';

-- ============================================================================
-- Fix job_type values to match code expectations
-- ============================================================================

-- The app uses: private (bool true/false via is_private column)
-- Database schema has: job_type with 'public'/'private'

-- Add is_private column if it doesn't exist
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;

-- Update is_private based on job_type
UPDATE jobs SET is_private = (job_type = 'private') WHERE is_private IS NULL;

-- Add index for is_private
CREATE INDEX IF NOT EXISTS idx_jobs_is_private ON jobs(is_private);

-- ============================================================================
-- Add missing timestamp columns referenced in code
-- ============================================================================

ALTER TABLE jobs ADD COLUMN IF NOT EXISTS started_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS paused_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS resumed_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS cancellation_reason TEXT; 