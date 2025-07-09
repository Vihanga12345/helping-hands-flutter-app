-- Fix Missing Database Elements Migration
-- This migration adds missing tables and columns that are causing runtime errors

-- 1. Fix ratings_reviews table - add missing helper_id column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'ratings_reviews' AND column_name = 'helper_id'
    ) THEN
        ALTER TABLE ratings_reviews ADD COLUMN helper_id UUID REFERENCES users(id);
        
        -- Update existing records to populate helper_id from jobs table
        UPDATE ratings_reviews 
        SET helper_id = jobs.assigned_helper_id 
        FROM jobs 
        WHERE ratings_reviews.job_id = jobs.id;
        
        RAISE NOTICE 'Added helper_id column to ratings_reviews table';
    END IF;
END $$;

-- 2. Create job_timers table if it doesn't exist
CREATE TABLE IF NOT EXISTS job_timers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    helper_id UUID NOT NULL REFERENCES users(id),
    helpee_id UUID NOT NULL REFERENCES users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'not_started' CHECK (status IN ('not_started', 'running', 'paused', 'completed')),
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    pause_start_time TIMESTAMP WITH TIME ZONE,
    total_paused_duration INTERVAL DEFAULT '00:00:00',
    total_duration INTERVAL DEFAULT '00:00:00',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT unique_job_timer UNIQUE (job_id),
    CONSTRAINT valid_times CHECK (end_time IS NULL OR end_time >= start_time)
);

-- 3. Create indexes for job_timers table
CREATE INDEX IF NOT EXISTS idx_job_timers_job_id ON job_timers(job_id);
CREATE INDEX IF NOT EXISTS idx_job_timers_helper_id ON job_timers(helper_id);
CREATE INDEX IF NOT EXISTS idx_job_timers_status ON job_timers(status);

-- 4. Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_job_timer_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_job_timers_updated_at ON job_timers;
CREATE TRIGGER update_job_timers_updated_at
    BEFORE UPDATE ON job_timers
    FOR EACH ROW
    EXECUTE FUNCTION update_job_timer_updated_at();

-- 5. Create function to start job timer
CREATE OR REPLACE FUNCTION start_job_timer(p_job_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_timer_record RECORD;
    v_job_record RECORD;
BEGIN
    -- Get job details
    SELECT * INTO v_job_record FROM jobs WHERE id = p_job_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Job not found');
    END IF;
    
    -- Check if timer already exists
    SELECT * INTO v_timer_record FROM job_timers WHERE job_id = p_job_id;
    
    IF FOUND THEN
        -- Update existing timer
        IF v_timer_record.status = 'paused' THEN
            -- Resume from pause
            UPDATE job_timers 
            SET 
                status = 'running',
                total_paused_duration = total_paused_duration + (NOW() - pause_start_time),
                pause_start_time = NULL,
                updated_at = NOW()
            WHERE job_id = p_job_id;
        ELSE
            -- Start timer
            UPDATE job_timers 
            SET 
                status = 'running',
                start_time = COALESCE(start_time, NOW()),
                updated_at = NOW()
            WHERE job_id = p_job_id;
        END IF;
    ELSE
        -- Create new timer
        INSERT INTO job_timers (job_id, helper_id, helpee_id, status, start_time)
        VALUES (p_job_id, v_job_record.assigned_helper_id, v_job_record.helpee_id, 'running', NOW());
    END IF;
    
    -- Update job status to started
    UPDATE jobs SET status = 'started' WHERE id = p_job_id;
    
    RETURN jsonb_build_object('success', true, 'message', 'Timer started successfully');
END;
$$ LANGUAGE plpgsql;

-- 6. Create function to pause job timer
CREATE OR REPLACE FUNCTION pause_job_timer(p_job_id UUID)
RETURNS JSONB AS $$
BEGIN
    UPDATE job_timers 
    SET 
        status = 'paused',
        pause_start_time = NOW(),
        updated_at = NOW()
    WHERE job_id = p_job_id AND status = 'running';
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Timer not found or not running');
    END IF;
    
    RETURN jsonb_build_object('success', true, 'message', 'Timer paused successfully');
END;
$$ LANGUAGE plpgsql;

-- 7. Create function to complete job timer
CREATE OR REPLACE FUNCTION complete_job_timer(p_job_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_timer_record RECORD;
    v_total_time INTERVAL;
BEGIN
    -- Get current timer state
    SELECT * INTO v_timer_record FROM job_timers WHERE job_id = p_job_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Timer not found');
    END IF;
    
    -- Calculate total duration
    IF v_timer_record.status = 'paused' THEN
        v_total_time := (v_timer_record.pause_start_time - v_timer_record.start_time) - v_timer_record.total_paused_duration;
    ELSE
        v_total_time := (NOW() - v_timer_record.start_time) - v_timer_record.total_paused_duration;
    END IF;
    
    -- Update timer
    UPDATE job_timers 
    SET 
        status = 'completed',
        end_time = NOW(),
        total_duration = v_total_time,
        updated_at = NOW()
    WHERE job_id = p_job_id;
    
    -- Update job status
    UPDATE jobs SET status = 'completed' WHERE id = p_job_id;
    
    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Timer completed successfully',
        'total_duration', EXTRACT(EPOCH FROM v_total_time)
    );
END;
$$ LANGUAGE plpgsql;

-- 8. Create function to get timer status
CREATE OR REPLACE FUNCTION get_job_timer_status(p_job_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_timer_record RECORD;
    v_current_duration INTERVAL;
    v_result JSONB;
BEGIN
    SELECT * INTO v_timer_record FROM job_timers WHERE job_id = p_job_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'exists', false,
            'status', 'not_started',
            'total_duration', 0
        );
    END IF;
    
    -- Calculate current duration
    IF v_timer_record.status = 'running' THEN
        v_current_duration := (NOW() - v_timer_record.start_time) - v_timer_record.total_paused_duration;
    ELSIF v_timer_record.status = 'paused' THEN
        v_current_duration := (v_timer_record.pause_start_time - v_timer_record.start_time) - v_timer_record.total_paused_duration;
    ELSE
        v_current_duration := v_timer_record.total_duration;
    END IF;
    
    RETURN jsonb_build_object(
        'exists', true,
        'status', v_timer_record.status,
        'start_time', v_timer_record.start_time,
        'end_time', v_timer_record.end_time,
        'total_duration', EXTRACT(EPOCH FROM v_current_duration),
        'total_paused_duration', EXTRACT(EPOCH FROM v_timer_record.total_paused_duration)
    );
END;
$$ LANGUAGE plpgsql;

-- 9. Insert seed data for existing jobs that might need timers
INSERT INTO job_timers (job_id, helper_id, helpee_id, status)
SELECT 
    j.id,
    j.assigned_helper_id,
    j.helpee_id,
    CASE 
        WHEN j.status = 'started' THEN 'running'
        WHEN j.status = 'completed' THEN 'completed'
        ELSE 'not_started'
    END
FROM jobs j
LEFT JOIN job_timers jt ON j.id = jt.job_id
WHERE jt.job_id IS NULL 
AND j.assigned_helper_id IS NOT NULL
AND j.status IN ('accepted', 'started', 'completed');

-- 10. Update any existing ratings_reviews records that don't have helper_id
UPDATE ratings_reviews 
SET helper_id = jobs.assigned_helper_id 
FROM jobs 
WHERE ratings_reviews.job_id = jobs.id 
AND ratings_reviews.helper_id IS NULL;

-- 11. Final status messages
DO $$
BEGIN
    RAISE NOTICE 'Database fix migration completed successfully';
    RAISE NOTICE 'Added missing helper_id column to ratings_reviews table';
    RAISE NOTICE 'Created job_timers table with all necessary functions';
    RAISE NOTICE 'Added seed data for existing jobs';
END $$; 