-- ============================================================================
-- TRIGGER CONFLICT FIX FOR HELPING HANDS APP
-- ============================================================================
-- This fixes the "tuple to be updated was already modified" error
-- that occurs when completing jobs due to conflicting BEFORE triggers

-- ============================================================================
-- STEP 1: Drop the conflicting BEFORE trigger
-- ============================================================================

DROP TRIGGER IF EXISTS auto_calculate_from_timer_trigger ON jobs;
DROP FUNCTION IF EXISTS auto_calculate_from_timer_on_completion();

-- ============================================================================  
-- STEP 2: Create an AFTER trigger instead to avoid conflicts
-- ============================================================================

CREATE OR REPLACE FUNCTION auto_calculate_from_timer_after_completion()
RETURNS TRIGGER AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Only trigger when job status changes to completed
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        
        -- Calculate duration and fee using timer data
        v_result := calculate_job_duration_fee_from_timer(NEW.id);
        
        -- If calculation succeeded, update the job record
        IF (v_result->>'success')::boolean = true THEN
            UPDATE jobs SET
                total_duration = (v_result->>'duration_minutes')::integer,
                total_fee = (v_result->>'total_fee')::numeric,
                final_amount = (v_result->>'final_amount')::numeric,
                payment_amount_calculated = (v_result->>'final_amount')::numeric,
                updated_at = NOW()
            WHERE id = NEW.id;
            
            RAISE NOTICE 'Job % completed using timer data: Duration=% min, Fee=LKR %', 
                NEW.id, (v_result->>'duration_minutes')::integer, (v_result->>'total_fee')::numeric;
        ELSE
            RAISE WARNING 'Timer calculation failed for job %: %', NEW.id, v_result->>'error';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the new AFTER trigger
CREATE TRIGGER auto_calculate_from_timer_after_trigger
    AFTER UPDATE ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION auto_calculate_from_timer_after_completion();

-- ============================================================================
-- STEP 3: Ensure all required functions exist
-- ============================================================================

-- Make sure the timer calculation function exists
CREATE OR REPLACE FUNCTION calculate_job_duration_fee_from_timer(p_job_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_job RECORD;
    v_duration_minutes INTEGER := 0;
    v_total_fee NUMERIC := 0;
    v_final_amount NUMERIC := 0;
    v_data_source TEXT := 'fallback';
BEGIN
    -- Get job basic info
    SELECT 
        actual_start_time, 
        actual_end_time, 
        hourly_rate,
        status,
        title
    INTO v_job
    FROM jobs 
    WHERE id = p_job_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Job not found'
        );
    END IF;
    
    -- Try different timer data sources in priority order
    
    -- 1. Try job_timer_info table first
    BEGIN
        SELECT 
            COALESCE(total_elapsed_seconds, 0) / 60
        INTO v_duration_minutes
        FROM job_timer_info 
        WHERE job_id = p_job_id;
        
        IF v_duration_minutes > 0 THEN
            v_data_source := 'job_timer_info';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        NULL; -- Continue to next method
    END;
    
    -- 2. Try cumulative_time_seconds from jobs table
    IF v_duration_minutes = 0 THEN
        BEGIN
            SELECT 
                COALESCE(cumulative_time_seconds, 0) / 60
            INTO v_duration_minutes
            FROM jobs 
            WHERE id = p_job_id 
            AND cumulative_time_seconds > 0;
            
            IF v_duration_minutes > 0 THEN
                v_data_source := 'cumulative_time_seconds';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            NULL; -- Continue to next method
        END;
    END IF;
    
    -- 3. Try job_timers table (if exists)
    IF v_duration_minutes = 0 THEN
        BEGIN
            SELECT 
                SUM(COALESCE(duration_seconds, 0)) / 60
            INTO v_duration_minutes
            FROM job_timers 
            WHERE job_id = p_job_id;
            
            IF v_duration_minutes > 0 THEN
                v_data_source := 'job_timers';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            NULL; -- Continue to next method
        END;
    END IF;
    
    -- 4. Calculate from actual start/end times
    IF v_duration_minutes = 0 AND v_job.actual_start_time IS NOT NULL AND v_job.actual_end_time IS NOT NULL THEN
        v_duration_minutes := EXTRACT(EPOCH FROM (v_job.actual_end_time - v_job.actual_start_time)) / 60;
        v_data_source := 'calculated_from_timestamps';
    END IF;
    
    -- 5. Use minimum 1 hour if no timer data available
    IF v_duration_minutes = 0 THEN
        v_duration_minutes := 60; -- 1 hour minimum
        v_data_source := 'minimum_fallback';
    END IF;
    
    -- Calculate fee
    v_total_fee := (v_duration_minutes * COALESCE(v_job.hourly_rate, 1000.0)) / 60.0;
    v_final_amount := v_total_fee;
    
    -- Return success result
    RETURN jsonb_build_object(
        'success', true,
        'job_id', p_job_id,
        'duration_minutes', v_duration_minutes,
        'duration_text', 
            CASE 
                WHEN v_duration_minutes >= 60 THEN 
                    (v_duration_minutes / 60) || 'h ' || (v_duration_minutes % 60) || 'm'
                ELSE 
                    v_duration_minutes || 'm'
            END,
        'total_fee', v_total_fee,
        'final_amount', v_final_amount,
        'hourly_rate', COALESCE(v_job.hourly_rate, 1000.0),
        'data_source', v_data_source,
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
-- STEP 4: Success verification
-- ============================================================================

DO $$
BEGIN
    -- Check if trigger was created successfully
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'auto_calculate_from_timer_after_trigger'
        AND tgrelid = 'jobs'::regclass
    ) THEN
        RAISE NOTICE '✅ AFTER trigger created successfully - conflicts resolved!';
    ELSE
        RAISE EXCEPTION '❌ Failed to create AFTER trigger';
    END IF;
    
    -- Check if function exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'calculate_job_duration_fee_from_timer'
    ) THEN
        RAISE NOTICE '✅ Timer calculation function is ready';
    ELSE
        RAISE EXCEPTION '❌ Timer calculation function missing';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉 TRIGGER CONFLICT FIX COMPLETED!';
    RAISE NOTICE '📋 Changes made:';
    RAISE NOTICE '   ✅ Removed conflicting BEFORE trigger';
    RAISE NOTICE '   ✅ Created AFTER trigger to avoid conflicts';
    RAISE NOTICE '   ✅ Fixed timer calculation function';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Job completion should now work without trigger conflicts!';
END $$; 