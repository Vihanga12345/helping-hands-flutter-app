-- Add Timer Columns for Simplified Timer System
-- Migration: 053_add_timer_columns.sql

-- Add timer-related columns to jobs table
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS elapsed_time_seconds INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS timer_status VARCHAR(20) DEFAULT 'stopped',
ADD COLUMN IF NOT EXISTS session_start_time TIMESTAMPTZ DEFAULT NULL,
ADD COLUMN IF NOT EXISTS last_timer_update TIMESTAMPTZ DEFAULT NULL;

-- Create index for timer status queries
CREATE INDEX IF NOT EXISTS idx_jobs_timer_status ON jobs(timer_status);
CREATE INDEX IF NOT EXISTS idx_jobs_elapsed_time ON jobs(elapsed_time_seconds);

-- Update existing jobs to have default timer status
UPDATE jobs 
SET timer_status = CASE 
    WHEN status = 'in_progress' THEN 'running'
    WHEN status = 'completed' THEN 'stopped'
    ELSE 'stopped'
END
WHERE timer_status IS NULL;

-- ✅ Timer columns added successfully! 