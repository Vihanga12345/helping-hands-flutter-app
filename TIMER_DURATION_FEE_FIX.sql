-- ============================================================================
-- TIMER-BASED DURATION & FEE CALCULATION FIX
-- ============================================================================
-- Execute this in Supabase SQL Editor to fix all timer and payment issues
-- Uses existing job_timer_info infrastructure for accurate calculations

-- ============================================================================
-- STEP 1: Create function to get timer-based duration and calculate fees
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_job_duration_fee_from_timer(p_job_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_timer_record RECORD;
    v_job_record RECORD;
    v_duration_seconds INTEGER;
    v_duration_minutes INTEGER;
    v_total_fee NUMERIC;
    v_final_amount NUMERIC;
    v_duration_text TEXT;
BEGIN
    -- Get job details
    SELECT hourly_rate, status, assigned_helper_id, helpee_id
    INTO v_job_record
    FROM jobs 
    WHERE id = p_job_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Job not found'
        );
    END IF;

    -- Get timer information (using existing timer infrastructure)
    -- Try multiple sources for elapsed time in order of preference
    
    -- First: Check job_timer_info view if it exists
    BEGIN
        SELECT current_elapsed_seconds INTO v_duration_seconds
        FROM job_timer_info 
        WHERE id = p_job_id;
    EXCEPTION WHEN OTHERS THEN
        v_duration_seconds := NULL;
    END;
    
    -- Second: Check cumulative_time_seconds or total_elapsed_seconds from jobs table
    IF v_duration_seconds IS NULL THEN
        SELECT 
            COALESCE(cumulative_time_seconds, total_elapsed_seconds, 0) 
        INTO v_duration_seconds
        FROM jobs 
        WHERE id = p_job_id;
    END IF;
    
    -- Third: Check job_timers table if it exists
    IF v_duration_seconds IS NULL OR v_duration_seconds = 0 THEN
        BEGIN
            SELECT EXTRACT(EPOCH FROM total_duration)::INTEGER 
            INTO v_duration_seconds
            FROM job_timers 
            WHERE job_id = p_job_id;
        EXCEPTION WHEN OTHERS THEN
            v_duration_seconds := COALESCE(v_duration_seconds, 0);
        END;
    END IF;
    
    -- Fourth: Calculate from actual_start_time and actual_end_time if available
    IF v_duration_seconds IS NULL OR v_duration_seconds = 0 THEN
        SELECT 
            EXTRACT(EPOCH FROM (actual_end_time - actual_start_time))::INTEGER
        INTO v_duration_seconds
        FROM jobs 
        WHERE id = p_job_id 
        AND actual_start_time IS NOT NULL 
        AND actual_end_time IS NOT NULL;
    END IF;
    
    -- Default to 1 hour minimum if no timer data found
    IF v_duration_seconds IS NULL OR v_duration_seconds = 0 THEN
        v_duration_seconds := 3600; -- 1 hour minimum
    END IF;
    
    -- Convert to minutes (rounded up)
    v_duration_minutes := CEIL(v_duration_seconds / 60.0);
    
    -- Calculate fee: (duration_seconds / 3600) * hourly_rate
    v_total_fee := ROUND((v_duration_seconds::NUMERIC / 3600.0) * COALESCE(v_job_record.hourly_rate, 1000.0), 2);
    
    -- Minimum payment of 1 hour
    IF v_total_fee < COALESCE(v_job_record.hourly_rate, 1000.0) THEN
        v_total_fee := COALESCE(v_job_record.hourly_rate, 1000.0);
        v_duration_minutes := 60; -- Show 1 hour minimum
    END IF;
    
    v_final_amount := v_total_fee;
    
    -- Format duration text
    v_duration_text := CASE 
        WHEN v_duration_minutes >= 60 THEN 
            (v_duration_minutes / 60) || 'h ' || (v_duration_minutes % 60) || 'm'
        ELSE 
            v_duration_minutes || 'm'
    END;
    
    -- Update job with calculated values
    UPDATE jobs 
    SET 
        total_duration = v_duration_minutes,
        total_fee = v_total_fee::INTEGER,
        final_amount = v_final_amount,
        payment_amount_calculated = v_final_amount,
        updated_at = NOW()
    WHERE id = p_job_id;
    
    -- Return comprehensive result
    RETURN jsonb_build_object(
        'success', true,
        'job_id', p_job_id,
        'duration_seconds', v_duration_seconds,
        'duration_minutes', v_duration_minutes,
        'duration_text', v_duration_text,
        'hourly_rate', COALESCE(v_job_record.hourly_rate, 1000.0),
        'total_fee', v_total_fee,
        'final_amount', v_final_amount,
        'helpee_id', v_job_record.helpee_id,
        'helper_id', v_job_record.assigned_helper_id,
        'is_calculated', true
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION calculate_job_duration_fee_from_timer(UUID) TO authenticated;

-- ============================================================================
-- STEP 2: Create function to get payment details for app (using timer data)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_timer_based_payment_details(p_job_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_job RECORD;
    v_timer_data JSONB;
BEGIN
    -- Get job basic details
    SELECT 
        id, title, status, helpee_id, assigned_helper_id, 
        job_category_name, hourly_rate
    INTO v_job
    FROM jobs 
    WHERE id = p_job_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('error', 'Job not found');
    END IF;
    
    -- Get timer-based calculation
    v_timer_data := calculate_job_duration_fee_from_timer(p_job_id);
    
    -- If calculation failed, return error
    IF (v_timer_data->>'success')::boolean = false THEN
        RETURN v_timer_data;
    END IF;
    
    -- Return formatted payment details
    RETURN jsonb_build_object(
        'job_id', v_job.id,
        'job_title', v_job.title,
        'status', v_job.status,
        'duration_minutes', (v_timer_data->>'duration_minutes')::integer,
        'duration_text', v_timer_data->>'duration_text',
        'hourly_rate', (v_timer_data->>'hourly_rate')::numeric,
        'total_fee', (v_timer_data->>'total_fee')::numeric,
        'final_amount', (v_timer_data->>'final_amount')::numeric,
        'helpee_id', v_job.helpee_id,
        'helper_id', v_job.assigned_helper_id,
        'category', COALESCE(v_job.job_category_name, 'General'),
        'is_calculated', true,
        'data_source', 'timer_based'
    );
    
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_timer_based_payment_details(UUID) TO authenticated;

-- ============================================================================
-- STEP 3: Update job completion trigger to use timer data
-- ============================================================================

CREATE OR REPLACE FUNCTION auto_calculate_from_timer_on_completion()
RETURNS TRIGGER AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Only trigger when job status changes to completed
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        
        -- Set actual_end_time if not already set
        IF NEW.actual_end_time IS NULL THEN
            NEW.actual_end_time := NOW();
        END IF;
        
        -- Calculate duration and fee using timer data
        v_result := calculate_job_duration_fee_from_timer(NEW.id);
        
        -- If calculation succeeded, update the NEW record
        IF (v_result->>'success')::boolean = true THEN
            NEW.total_duration := (v_result->>'duration_minutes')::integer;
            NEW.total_fee := (v_result->>'total_fee')::numeric;
            NEW.final_amount := (v_result->>'final_amount')::numeric;
            NEW.payment_amount_calculated := (v_result->>'final_amount')::numeric;
            
            RAISE NOTICE 'Job % completed using timer data: Duration=% min, Fee=LKR %', 
                NEW.id, NEW.total_duration, NEW.total_fee;
        ELSE
            RAISE WARNING 'Timer calculation failed for job %: %', NEW.id, v_result->>'error';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger and create new one
DROP TRIGGER IF EXISTS auto_calculate_duration_trigger ON jobs;
DROP TRIGGER IF EXISTS auto_calculate_from_timer_trigger ON jobs;

CREATE TRIGGER auto_calculate_from_timer_trigger
    BEFORE UPDATE ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION auto_calculate_from_timer_on_completion();

-- ============================================================================
-- STEP 4: Fix payment confirmation function to use timer data
-- ============================================================================

-- Drop existing problematic function
DROP FUNCTION IF EXISTS initiate_cash_payment_confirmation(uuid);

-- Create new function using timer-based calculation
CREATE OR REPLACE FUNCTION initiate_timer_based_payment_confirmation(job_id_param UUID)
RETURNS TABLE (
  success integer,
  message text,
  payment_amount_calculated numeric,
  helpee_id uuid,
  helpee_first_name text,
  helpee_last_name text,
  helper_id uuid,
  helper_first_name text,
  helper_last_name text,
  duration_text text,
  duration_minutes integer
) AS $$
DECLARE
  payment_data JSONB;
  helpee_record RECORD;
  helper_record RECORD;
BEGIN
  -- Get timer-based payment calculation
  payment_data := get_timer_based_payment_details(job_id_param);
  
  -- Check if calculation failed
  IF payment_data ? 'error' THEN
    RETURN QUERY SELECT 
      0, payment_data->>'error', 0::numeric,
      NULL::uuid, NULL::text, NULL::text, 
      NULL::uuid, NULL::text, NULL::text,
      NULL::text, 0;
    RETURN;
  END IF;

  -- Get helpee details
  SELECT id, first_name, last_name INTO helpee_record 
  FROM users WHERE id = (payment_data->>'helpee_id')::uuid;
  
  IF NOT FOUND THEN
    RETURN QUERY SELECT 
      0, 'Helpee not found', 0::numeric,
      NULL::uuid, NULL::text, NULL::text, 
      NULL::uuid, NULL::text, NULL::text,
      NULL::text, 0;
    RETURN;
  END IF;
  
  -- Get helper details
  SELECT id, first_name, last_name INTO helper_record 
  FROM users WHERE id = (payment_data->>'helper_id')::uuid;
  
  IF NOT FOUND THEN
    RETURN QUERY SELECT 
      0, 'Helper not found', 0::numeric,
      NULL::uuid, NULL::text, NULL::text, 
      NULL::uuid, NULL::text, NULL::text,
      NULL::text, 0;
    RETURN;
  END IF;

  -- Return success with all required data
  RETURN QUERY SELECT
    1 AS success,
    'Payment confirmation initiated with timer data.' AS message,
    (payment_data->>'final_amount')::numeric,
    helpee_record.id,
    helpee_record.first_name,
    helpee_record.last_name,
    helper_record.id,
    helper_record.first_name,
    helper_record.last_name,
    payment_data->>'duration_text',
    (payment_data->>'duration_minutes')::integer;

EXCEPTION
  WHEN OTHERS THEN
    RETURN QUERY SELECT 
      0, SQLERRM, 0::numeric,
      NULL::uuid, NULL::text, NULL::text, 
      NULL::uuid, NULL::text, NULL::text,
      NULL::text, 0;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION initiate_timer_based_payment_confirmation(UUID) TO authenticated;

-- ============================================================================
-- STEP 5: Status verification and summary
-- ============================================================================

DO $$
DECLARE
    v_functions_count INTEGER;
    v_completed_jobs_count INTEGER;
    v_timer_jobs_count INTEGER;
BEGIN
    -- Count functions
    SELECT COUNT(*) INTO v_functions_count
    FROM information_schema.routines 
    WHERE routine_name IN (
        'calculate_job_duration_fee_from_timer', 
        'get_timer_based_payment_details',
        'initiate_timer_based_payment_confirmation'
    );
    
    -- Count completed jobs
    SELECT COUNT(*) INTO v_completed_jobs_count
    FROM jobs WHERE status = 'completed';
    
    -- Count jobs with timer data
    SELECT COUNT(*) INTO v_timer_jobs_count
    FROM jobs 
    WHERE status = 'completed' 
    AND (
        cumulative_time_seconds > 0 OR 
        total_elapsed_seconds > 0 OR 
        (actual_start_time IS NOT NULL AND actual_end_time IS NOT NULL)
    );
    
    -- Report results
    RAISE NOTICE '';
    RAISE NOTICE '🎉 TIMER-BASED DURATION & FEE CALCULATION FIX COMPLETED!';
    RAISE NOTICE '===========================================================';
    RAISE NOTICE '✅ Database Functions: % of 3 created successfully', v_functions_count;
    RAISE NOTICE '✅ Completed Jobs: % total', v_completed_jobs_count;
    RAISE NOTICE '✅ Jobs with Timer Data: % of % completed jobs', v_timer_jobs_count, v_completed_jobs_count;
    RAISE NOTICE '';
    RAISE NOTICE '📋 New Functions Available:';
    RAISE NOTICE '   • calculate_job_duration_fee_from_timer(job_id) - Uses timer infrastructure';
    RAISE NOTICE '   • get_timer_based_payment_details(job_id) - For payment pages';
    RAISE NOTICE '   • initiate_timer_based_payment_confirmation(job_id) - Fixed payment flow';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Timer Data Sources (in priority order):';
    RAISE NOTICE '   1. job_timer_info view (current_elapsed_seconds)';
    RAISE NOTICE '   2. jobs.cumulative_time_seconds or jobs.total_elapsed_seconds';
    RAISE NOTICE '   3. job_timers.total_duration';
    RAISE NOTICE '   4. Calculated from actual_start_time to actual_end_time';
    RAISE NOTICE '   5. Default 1-hour minimum if no timer data';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Your app now uses REAL timer data for duration and fee calculations!';
    
END $$; 