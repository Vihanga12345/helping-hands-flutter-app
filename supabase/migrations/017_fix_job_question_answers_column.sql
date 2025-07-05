-- HELPING HANDS APP - Fix Job Question Answers Column Naming
-- ============================================================================
-- Migration 017: Fix job_question_answers table column inconsistency
-- Date: January 2025
-- Purpose: Fix PostgrestException for 'answer' column in job_question_answers

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- STEP 1: Fix Column Naming Inconsistency
-- ============================================================================

-- Check if 'answer' column exists, if not rename answer_text to answer
DO $$ 
BEGIN
    -- Check if 'answer' column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_question_answers' 
        AND column_name = 'answer'
    ) THEN
        -- Rename answer_text to answer for backwards compatibility
        ALTER TABLE job_question_answers RENAME COLUMN answer_text TO answer;
        RAISE NOTICE 'Renamed answer_text to answer in job_question_answers table';
    ELSE
        RAISE NOTICE 'Column answer already exists in job_question_answers table';
    END IF;
END $$;

-- ============================================================================
-- STEP 2: Ensure All Answer Type Columns Exist
-- ============================================================================

-- Add missing answer type columns if they don't exist
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer_number DECIMAL(10,2);
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer_date DATE;
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer_time TIME;
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer_boolean BOOLEAN;
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS selected_options JSONB;

-- Add backup text column for compatibility
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer_text TEXT;

-- ============================================================================
-- STEP 3: Data Migration and Cleanup
-- ============================================================================

-- Copy data from answer to answer_text for backup compatibility
UPDATE job_question_answers 
SET answer_text = answer 
WHERE answer IS NOT NULL AND answer_text IS NULL;

-- ============================================================================
-- STEP 4: Add Enhanced Timer System Fields to Jobs Table (Non-Conflicting)
-- ============================================================================

-- Add additional timer tracking fields that don't conflict with existing ones
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS session_start_time TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS session_pause_time TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS session_events JSONB DEFAULT '[]';
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS cumulative_time_seconds INTEGER DEFAULT 0;

-- ============================================================================
-- STEP 5: Add Helper Assignment Enhancement Fields
-- ============================================================================

-- Add helper display fields for better UX
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helper_profile_image_url TEXT;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helper_rating DECIMAL(3,2) DEFAULT 0;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helper_job_count INTEGER DEFAULT 0;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helper_first_name VARCHAR(100);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helper_last_name VARCHAR(100);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helper_phone VARCHAR(20);

-- ============================================================================
-- STEP 6: Create Enhanced Views for Job Details
-- ============================================================================

-- Drop existing view if it exists
DROP VIEW IF EXISTS job_details_with_helper;

-- Create comprehensive view for job details with helper information
CREATE OR REPLACE VIEW job_details_with_helper AS
SELECT 
    -- Job fields (explicit selection to avoid conflicts)
    j.id, j.helpee_id, j.assigned_helper_id, j.job_type, j.hourly_rate,
    j.description, j.location_address, j.location_latitude, j.location_longitude,
    j.scheduled_date, j.scheduled_time, j.status,
    j.created_at, j.updated_at,
    -- Use existing timer_status from migration 015
    COALESCE(j.timer_status, 'not_started') as timer_status,
    -- Use new non-conflicting timer fields
    j.session_start_time, j.session_pause_time, j.session_events, j.cumulative_time_seconds,
    -- Use existing actual start/end times
    j.actual_start_time, j.actual_end_time,
    -- Helper information from joined table (prioritized over job columns)
    COALESCE(h.first_name, j.helper_first_name) as helper_first_name,
    COALESCE(h.last_name, j.helper_last_name) as helper_last_name,
    COALESCE(h.profile_image_url, j.helper_profile_image_url) as helper_profile_image,
    COALESCE(h.phone, j.helper_phone) as helper_phone,
    h.email as helper_email,
    h.location_city as helper_location,
    COALESCE(
        (SELECT AVG(rating)::DECIMAL(3,2) FROM ratings_reviews 
         WHERE reviewee_id = h.id AND review_type = 'helpee_to_helper'),
        j.helper_rating,
        0
    ) as helper_avg_rating,
    COALESCE(
        (SELECT COUNT(*)::INTEGER FROM jobs 
         WHERE assigned_helper_id = h.id AND status = 'completed'),
        j.helper_job_count,
        0
    ) as helper_completed_jobs,
    -- Helpee information
    he.first_name as helpee_first_name,
    he.last_name as helpee_last_name,
    he.profile_image_url as helpee_profile_image,
    he.phone as helpee_phone,
    he.email as helpee_email,
    he.location_city as helpee_location
FROM jobs j
LEFT JOIN users h ON j.assigned_helper_id = h.id AND h.user_type = 'helper'
LEFT JOIN users he ON j.helpee_id = he.id AND he.user_type = 'helpee';

-- ============================================================================
-- STEP 7: Add Indexes for Performance (Non-Conflicting)
-- ============================================================================

-- Jobs table session indexes (using new non-conflicting column names)
CREATE INDEX IF NOT EXISTS idx_jobs_session_start ON jobs(session_start_time);
CREATE INDEX IF NOT EXISTS idx_jobs_cumulative_time ON jobs(cumulative_time_seconds);
CREATE INDEX IF NOT EXISTS idx_jobs_helper_assignment_status ON jobs(assigned_helper_id, status);

-- ============================================================================
-- STEP 8: Create Simple Timer Helper Functions
-- ============================================================================

-- Function to calculate session elapsed time
CREATE OR REPLACE FUNCTION calculate_session_elapsed_time(job_id UUID)
RETURNS INTEGER AS $$
DECLARE
    job_record RECORD;
    elapsed_seconds INTEGER := 0;
BEGIN
    SELECT session_start_time, session_pause_time, cumulative_time_seconds, timer_status
    INTO job_record 
    FROM jobs 
    WHERE id = job_id;
    
    IF job_record.session_start_time IS NULL THEN
        RETURN COALESCE(job_record.cumulative_time_seconds, 0);
    END IF;
    
    -- If currently running, add time since last start
    IF job_record.timer_status = 'running' THEN
        elapsed_seconds := COALESCE(job_record.cumulative_time_seconds, 0) + 
                          EXTRACT(EPOCH FROM (NOW() - job_record.session_start_time))::INTEGER;
    ELSE
        elapsed_seconds := COALESCE(job_record.cumulative_time_seconds, 0);
    END IF;
    
    RETURN elapsed_seconds;
END;
$$ LANGUAGE plpgsql;

-- Function to format elapsed time as HH:MM:SS
CREATE OR REPLACE FUNCTION format_session_time(seconds INTEGER)
RETURNS TEXT AS $$
DECLARE
    hours INTEGER;
    minutes INTEGER;
    remaining_seconds INTEGER;
BEGIN
    IF seconds IS NULL OR seconds < 0 THEN
        RETURN '00:00:00';
    END IF;
    
    hours := seconds / 3600;
    minutes := (seconds % 3600) / 60;
    remaining_seconds := seconds % 60;
    
    RETURN LPAD(hours::TEXT, 2, '0') || ':' || 
           LPAD(minutes::TEXT, 2, '0') || ':' || 
           LPAD(remaining_seconds::TEXT, 2, '0');
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 9: Verification and Cleanup
-- ============================================================================

-- Verify the migration
DO $$ 
BEGIN
    -- Check if answer column exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_question_answers' 
        AND column_name = 'answer'
    ) THEN
        RAISE NOTICE '✅ Migration successful: answer column exists in job_question_answers';
    ELSE
        RAISE EXCEPTION '❌ Migration failed: answer column missing from job_question_answers';
    END IF;
    
    -- Check if session timer fields exist
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'cumulative_time_seconds'
    ) THEN
        RAISE NOTICE '✅ Session timer fields added successfully to jobs table';
    ELSE
        RAISE EXCEPTION '❌ Session timer fields missing from jobs table';
    END IF;
    
    -- Check if view exists
    IF EXISTS (
        SELECT 1 FROM information_schema.views 
        WHERE table_name = 'job_details_with_helper'
    ) THEN
        RAISE NOTICE '✅ job_details_with_helper view created successfully';
    ELSE
        RAISE EXCEPTION '❌ job_details_with_helper view not created';
    END IF;
END $$;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Summary of changes:
-- 1. ✅ Fixed job_question_answers column naming (answer_text → answer)
-- 2. ✅ Added non-conflicting session timer tracking to jobs table
-- 3. ✅ Added helper assignment display fields to jobs table
-- 4. ✅ Created job_details_with_helper view for enhanced queries
-- 5. ✅ Added session timer helper functions
-- 6. ✅ Added performance indexes for session timer queries
-- 7. ✅ Added verification checks for successful migration 