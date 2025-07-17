-- ============================================================================
-- COMPREHENSIVE TIMER AND PAYMENT FIX - Migration 048
-- ============================================================================
-- Fixes payment function field names and implements complete timer system
-- Run this in Supabase SQL Editor

-- ============================================================================
-- 1. FIX PAYMENT FUNCTION WITH CORRECT FIELD NAMES
-- ============================================================================

-- Drop existing function with wrong field reference
DROP FUNCTION IF EXISTS initiate_cash_payment_confirmation(uuid);

-- Create fixed payment function using correct field names
CREATE OR REPLACE FUNCTION initiate_cash_payment_confirmation(job_id_param uuid)
RETURNS TABLE (
  success int,
  message text,
  payment_amount_calculated numeric,
  helpee_id uuid,
  helpee_first_name text,
  helpee_last_name text,
  helper_id uuid,
  helper_first_name text,
  helper_last_name text
) AS $$
DECLARE
  job_record RECORD;
  helpee_record RECORD;
  helper_record RECORD;
  calculated_amount NUMERIC;
  total_seconds INTEGER;
BEGIN
  -- Get job details
  SELECT * INTO job_record FROM jobs WHERE id = job_id_param;
  IF NOT FOUND THEN
    RETURN QUERY SELECT 0, 'Job not found', 0::numeric, NULL::uuid, NULL::text, NULL::text, NULL::uuid, NULL::text, NULL::text;
    RETURN;
  END IF;

  -- Get total elapsed seconds using existing fields
  total_seconds := COALESCE(job_record.total_elapsed_seconds, job_record.cumulative_time_seconds, 0);
  
  -- If no timer data, use estimated hours
  IF total_seconds = 0 AND job_record.estimated_hours IS NOT NULL THEN
    total_seconds := ROUND(job_record.estimated_hours * 3600);
  END IF;
  
  -- If still no data, default to 1 hour minimum
  IF total_seconds = 0 THEN
    total_seconds := 3600; -- 1 hour minimum
  END IF;

  -- Calculate payment amount: (total_seconds / 3600) * hourly_rate
  calculated_amount := ROUND((total_seconds::DECIMAL / 3600.0) * COALESCE(job_record.hourly_rate, 50.00), 2);
  
  -- Minimum payment of 1 hour
  IF calculated_amount < COALESCE(job_record.hourly_rate, 50.00) THEN
    calculated_amount := COALESCE(job_record.hourly_rate, 50.00);
  END IF;

  -- Update job with calculated amount
  UPDATE jobs
  SET payment_amount_calculated = calculated_amount
  WHERE id = job_id_param;

  -- Get helpee details
  SELECT u.id, u.first_name, u.last_name INTO helpee_record FROM users u WHERE u.id = job_record.helpee_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT 0, 'Helpee not found', 0::numeric, NULL::uuid, NULL::text, NULL::text, NULL::uuid, NULL::text, NULL::text;
    RETURN;
  END IF;
  
  -- Get helper details
  SELECT u.id, u.first_name, u.last_name INTO helper_record FROM users u WHERE u.id = job_record.assigned_helper_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT 0, 'Helper not found', 0::numeric, NULL::uuid, NULL::text, NULL::text, NULL::uuid, NULL::text, NULL::text;
    RETURN;
  END IF;

  RETURN QUERY SELECT
    1 AS success,
    'Payment confirmation initiated.' AS message,
    calculated_amount,
    helpee_record.id,
    helpee_record.first_name,
    helpee_record.last_name,
    helper_record.id,
    helper_record.first_name,
    helper_record.last_name;

EXCEPTION
  WHEN OTHERS THEN
    RETURN QUERY SELECT 0, SQLERRM, 0::numeric, NULL::uuid, NULL::text, NULL::text, NULL::uuid, NULL::text, NULL::text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 2. COMPREHENSIVE TIMER SYSTEM FUNCTIONS
-- ============================================================================

-- Function to start job timer
CREATE OR REPLACE FUNCTION start_job_timer(
  p_job_id UUID,
  p_helper_id UUID
) RETURNS JSONB AS $$
DECLARE
  job_exists BOOLEAN;
  result JSONB;
BEGIN
  -- Check if job exists and helper is assigned
  SELECT EXISTS(
    SELECT 1 FROM jobs 
    WHERE id = p_job_id 
    AND assigned_helper_id = p_helper_id 
    AND status IN ('accepted', 'started', 'in_progress')
  ) INTO job_exists;
  
  IF NOT job_exists THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Job not found or not authorized'
    );
  END IF;
  
  -- Update job timer status
  UPDATE jobs SET
    timer_status = 'running',
    session_start_time = NOW(),
    session_pause_time = NULL,
    is_timer_running = true,
    status = CASE WHEN status = 'accepted' THEN 'in_progress' ELSE status END,
    updated_at = NOW()
  WHERE id = p_job_id;
  
  -- Insert timer session record
  INSERT INTO job_timer_sessions (
    job_id, 
    helper_id, 
    session_start_time,
    session_type
  ) VALUES (
    p_job_id,
    p_helper_id,
    NOW(),
    'work'
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Timer started successfully',
    'timer_status', 'running',
    'started_at', NOW()
  );
END;
$$ LANGUAGE plpgsql;

-- Function to pause job timer
CREATE OR REPLACE FUNCTION pause_job_timer(
  p_job_id UUID,
  p_helper_id UUID
) RETURNS JSONB AS $$
DECLARE
  job_record RECORD;
  session_record RECORD;
  session_duration INTEGER;
  result JSONB;
BEGIN
  -- Get current job details
  SELECT * INTO job_record FROM jobs 
  WHERE id = p_job_id 
  AND assigned_helper_id = p_helper_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Job not found or not authorized'
    );
  END IF;
  
  IF job_record.timer_status != 'running' THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Timer is not running'
    );
  END IF;
  
  -- Get current session
  SELECT * INTO session_record FROM job_timer_sessions
  WHERE job_id = p_job_id 
  AND session_end_time IS NULL
  ORDER BY session_start_time DESC
  LIMIT 1;
  
  IF FOUND THEN
    -- Calculate session duration in seconds
    session_duration := EXTRACT(EPOCH FROM (NOW() - session_record.session_start_time))::INTEGER;
    
    -- Update session end time and duration
    UPDATE job_timer_sessions SET
      session_end_time = NOW(),
      duration_minutes = ROUND(session_duration / 60.0)
    WHERE id = session_record.id;
    
    -- Update job cumulative time
    UPDATE jobs SET
      cumulative_time_seconds = COALESCE(cumulative_time_seconds, 0) + session_duration,
      total_elapsed_seconds = COALESCE(total_elapsed_seconds, 0) + session_duration,
      timer_status = 'paused',
      session_pause_time = NOW(),
      is_timer_running = false,
      updated_at = NOW()
    WHERE id = p_job_id;
  END IF;
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Timer paused successfully',
    'timer_status', 'paused',
    'paused_at', NOW(),
    'session_duration_seconds', session_duration
  );
END;
$$ LANGUAGE plpgsql;

-- Function to resume job timer
CREATE OR REPLACE FUNCTION resume_job_timer(
  p_job_id UUID,
  p_helper_id UUID
) RETURNS JSONB AS $$
DECLARE
  job_exists BOOLEAN;
  result JSONB;
BEGIN
  -- Check if job exists and is paused
  SELECT EXISTS(
    SELECT 1 FROM jobs 
    WHERE id = p_job_id 
    AND assigned_helper_id = p_helper_id 
    AND timer_status = 'paused'
  ) INTO job_exists;
  
  IF NOT job_exists THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Job not found, not authorized, or not paused'
    );
  END IF;
  
  -- Update job timer status
  UPDATE jobs SET
    timer_status = 'running',
    session_start_time = NOW(),
    session_pause_time = NULL,
    is_timer_running = true,
    updated_at = NOW()
  WHERE id = p_job_id;
  
  -- Insert new timer session
  INSERT INTO job_timer_sessions (
    job_id,
    helper_id,
    session_start_time,
    session_type
  ) VALUES (
    p_job_id,
    p_helper_id,
    NOW(),
    'work'
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Timer resumed successfully',
    'timer_status', 'running',
    'resumed_at', NOW()
  );
END;
$$ LANGUAGE plpgsql;

-- Function to complete job with timer
CREATE OR REPLACE FUNCTION complete_job_timer(
  p_job_id UUID,
  p_helper_id UUID
) RETURNS JSONB AS $$
DECLARE
  job_record RECORD;
  session_record RECORD;
  session_duration INTEGER;
  total_duration INTEGER;
  calculated_amount NUMERIC;
  result JSONB;
BEGIN
  -- Get current job details
  SELECT * INTO job_record FROM jobs 
  WHERE id = p_job_id 
  AND assigned_helper_id = p_helper_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', 'Job not found or not authorized'
    );
  END IF;
  
  -- If timer is running, pause it first
  IF job_record.timer_status = 'running' THEN
    -- Get current session
    SELECT * INTO session_record FROM job_timer_sessions
    WHERE job_id = p_job_id 
    AND session_end_time IS NULL
    ORDER BY session_start_time DESC
    LIMIT 1;
    
    IF FOUND THEN
      -- Calculate session duration
      session_duration := EXTRACT(EPOCH FROM (NOW() - session_record.session_start_time))::INTEGER;
      
      -- Update session
      UPDATE job_timer_sessions SET
        session_end_time = NOW(),
        duration_minutes = ROUND(session_duration / 60.0)
      WHERE id = session_record.id;
      
      -- Update cumulative time
      UPDATE jobs SET
        cumulative_time_seconds = COALESCE(cumulative_time_seconds, 0) + session_duration,
        total_elapsed_seconds = COALESCE(total_elapsed_seconds, 0) + session_duration
      WHERE id = p_job_id;
    END IF;
  END IF;
  
  -- Get final total duration
  SELECT COALESCE(cumulative_time_seconds, total_elapsed_seconds, 0) 
  INTO total_duration FROM jobs WHERE id = p_job_id;
  
  -- Calculate final payment amount
  calculated_amount := ROUND((total_duration::DECIMAL / 3600.0) * COALESCE(job_record.hourly_rate, 50.00), 2);
  
  -- Minimum payment of 1 hour
  IF calculated_amount < COALESCE(job_record.hourly_rate, 50.00) THEN
    calculated_amount := COALESCE(job_record.hourly_rate, 50.00);
  END IF;
  
  -- Update job as completed
  UPDATE jobs SET
    status = 'completed',
    timer_status = 'completed',
    is_timer_running = false,
    completed_at = NOW(),
    final_amount = calculated_amount,
    payment_amount_calculated = calculated_amount,
    actual_end_time = NOW(),
    updated_at = NOW()
  WHERE id = p_job_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Job completed successfully',
    'timer_status', 'completed',
    'total_duration_seconds', total_duration,
    'total_hours', ROUND(total_duration::DECIMAL / 3600.0, 2),
    'calculated_amount', calculated_amount,
    'completed_at', NOW()
  );
END;
$$ LANGUAGE plpgsql;

-- Function to get current timer status
CREATE OR REPLACE FUNCTION get_timer_status(p_job_id UUID)
RETURNS TABLE (
  job_id UUID,
  timer_status VARCHAR,
  is_running BOOLEAN,
  total_duration_seconds INTEGER,
  current_session_start TIMESTAMP,
  total_hours NUMERIC,
  calculated_amount NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    j.id,
    j.timer_status,
    j.is_timer_running,
    COALESCE(j.cumulative_time_seconds, j.total_elapsed_seconds, 0) +
    CASE 
      WHEN j.is_timer_running AND j.session_start_time IS NOT NULL THEN
        EXTRACT(EPOCH FROM (NOW() - j.session_start_time))::INTEGER
      ELSE 0
    END as total_duration_seconds,
    j.session_start_time,
    ROUND((COALESCE(j.cumulative_time_seconds, j.total_elapsed_seconds, 0) +
    CASE 
      WHEN j.is_timer_running AND j.session_start_time IS NOT NULL THEN
        EXTRACT(EPOCH FROM (NOW() - j.session_start_time))::INTEGER
      ELSE 0
    END)::DECIMAL / 3600.0, 2) as total_hours,
    ROUND(((COALESCE(j.cumulative_time_seconds, j.total_elapsed_seconds, 0) +
    CASE 
      WHEN j.is_timer_running AND j.session_start_time IS NOT NULL THEN
        EXTRACT(EPOCH FROM (NOW() - j.session_start_time))::INTEGER
      ELSE 0
    END)::DECIMAL / 3600.0) * COALESCE(j.hourly_rate, 50.00), 2) as calculated_amount
  FROM jobs j
  WHERE j.id = p_job_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 3. ENABLE REAL-TIME UPDATES FOR TIMER SYNCHRONIZATION (SAFE)
-- ============================================================================

-- Check and add jobs table to publication only if not already added
DO $$
BEGIN
  -- Try to add jobs table to publication, ignore if already exists
  BEGIN
    ALTER publication supabase_realtime ADD TABLE jobs;
    RAISE NOTICE 'Added jobs table to supabase_realtime publication';
  EXCEPTION 
    WHEN duplicate_object THEN
      RAISE NOTICE 'Jobs table already in supabase_realtime publication';
    WHEN OTHERS THEN
      RAISE NOTICE 'Could not add jobs table to publication: %', SQLERRM;
  END;
END $$;

-- Add trigger to notify timer updates
CREATE OR REPLACE FUNCTION notify_timer_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Only notify for timer-related changes
  IF (OLD.timer_status IS DISTINCT FROM NEW.timer_status) OR
     (OLD.is_timer_running IS DISTINCT FROM NEW.is_timer_running) OR
     (OLD.cumulative_time_seconds IS DISTINCT FROM NEW.cumulative_time_seconds) OR
     (OLD.total_elapsed_seconds IS DISTINCT FROM NEW.total_elapsed_seconds) THEN
    
    PERFORM pg_notify(
      'timer_update',
      json_build_object(
        'job_id', NEW.id,
        'timer_status', NEW.timer_status,
        'is_running', NEW.is_timer_running,
        'total_seconds', COALESCE(NEW.cumulative_time_seconds, NEW.total_elapsed_seconds, 0)
      )::text
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for timer updates
DROP TRIGGER IF EXISTS timer_update_trigger ON jobs;
CREATE TRIGGER timer_update_trigger
  AFTER UPDATE ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION notify_timer_update();

-- ============================================================================
-- 4. INITIALIZE TIMER STATUS FOR EXISTING JOBS
-- ============================================================================

-- Set default timer status for existing jobs
UPDATE jobs SET
  timer_status = CASE
    WHEN status = 'completed' THEN 'completed'
    WHEN status IN ('started', 'in_progress') AND is_timer_running = true THEN 'running'
    WHEN status IN ('started', 'in_progress') AND is_timer_running = false THEN 'paused'
    ELSE 'not_started'
  END,
  cumulative_time_seconds = COALESCE(cumulative_time_seconds, total_elapsed_seconds, 0)
WHERE timer_status IS NULL OR timer_status = '';

-- ============================================================================
-- 5. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_jobs_timer_status ON jobs(id, timer_status, is_timer_running);
CREATE INDEX IF NOT EXISTS idx_job_timer_sessions_active ON job_timer_sessions(job_id, session_end_time) WHERE session_end_time IS NULL;
CREATE INDEX IF NOT EXISTS idx_jobs_real_time_updates ON jobs(id, updated_at, timer_status);

-- Success message
SELECT 'Timer system and payment fix migration completed successfully!' as status; 