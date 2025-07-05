-- Migration: Add job_ignores table
-- Description: Table to track which jobs a helper has ignored (for public jobs)

-- Create job_ignores table
CREATE TABLE IF NOT EXISTS job_ignores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    helper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    ignored_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure a helper can only ignore a job once
    UNIQUE(job_id, helper_id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_job_ignores_helper_id ON job_ignores(helper_id);
CREATE INDEX IF NOT EXISTS idx_job_ignores_job_id ON job_ignores(job_id);
CREATE INDEX IF NOT EXISTS idx_job_ignores_ignored_at ON job_ignores(ignored_at);

-- Add RLS policies
ALTER TABLE job_ignores ENABLE ROW LEVEL SECURITY;

-- Helpers can only see and manage their own ignored jobs
CREATE POLICY "Helpers can manage their own ignored jobs" ON job_ignores
    FOR ALL USING (helper_id = auth.uid());

-- Comments
COMMENT ON TABLE job_ignores IS 'Tracks which public jobs helpers have chosen to ignore';
COMMENT ON COLUMN job_ignores.job_id IS 'The job that was ignored';
COMMENT ON COLUMN job_ignores.helper_id IS 'The helper who ignored the job';
COMMENT ON COLUMN job_ignores.ignored_at IS 'When the job was ignored'; 