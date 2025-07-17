-- ============================================================================
-- FINAL JOB DURATION & FEE CALCULATION FIX
-- Execute this in Supabase SQL Editor to ensure proper time tracking
-- Date: January 2025 - HELPING HANDS APP
-- ============================================================================

-- ============================================================================
-- STEP 1: Add required columns to jobs table (safe to run multiple times)
-- ============================================================================

-- Add total_duration column (in minutes)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' AND column_name = 'total_duration'
    ) THEN
        ALTER TABLE public.jobs ADD COLUMN total_duration INTEGER DEFAULT NULL;
        RAISE NOTICE '✅ Added total_duration column to jobs table';
    ELSE
        RAISE NOTICE 'ℹ️  total_duration column already exists';
    END IF;
END $$;

-- Add total_fee column (in LKR)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' AND column_name = 'total_fee'
    ) THEN
        ALTER TABLE public.jobs ADD COLUMN total_fee INTEGER DEFAULT NULL;
        RAISE NOTICE '✅ Added total_fee column to jobs table';
    ELSE
        RAISE NOTICE 'ℹ️  total_fee column already exists';
    END IF;
END $$;

-- Add final_amount column (for payment display)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' AND column_name = 'final_amount'
    ) THEN
        ALTER TABLE public.jobs ADD COLUMN final_amount DECIMAL(10,2) DEFAULT NULL;
        RAISE NOTICE '✅ Added final_amount column to jobs table';
    ELSE
        RAISE NOTICE 'ℹ️  final_amount column already exists';
    END IF;
END $$;

-- Add comments for clarity
COMMENT ON COLUMN jobs.total_duration IS 'Total duration of the job in minutes, calculated from actual_start_time and actual_end_time';
COMMENT ON COLUMN jobs.total_fee IS 'Total calculated fee in LKR, calculated as (total_duration * hourly_rate / 60)';
COMMENT ON COLUMN jobs.final_amount IS 'Final amount to be paid/displayed in payment pages';

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_jobs_total_duration ON jobs(total_duration) WHERE total_duration IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_jobs_final_amount ON jobs(final_amount) WHERE final_amount IS NOT NULL;

-- ============================================================================
-- STEP 2: Create main calculation function
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_and_save_job_duration_fee(p_job_id UUID)
RETURNS JSON AS $$
DECLARE
    v_job_record RECORD;
    v_duration_minutes INTEGER;
    v_total_fee INTEGER;
    v_final_amount DECIMAL(10,2);
BEGIN
    -- Get job details
    SELECT 
        actual_start_time, 
        actual_end_time, 
        hourly_rate,
        status
    INTO v_job_record
    FROM jobs 
    WHERE id = p_job_id;
    
    -- Check if job exists
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Job not found'
        );
    END IF;
    
    -- Check if job has start and end times
    IF v_job_record.actual_start_time IS NULL OR v_job_record.actual_end_time IS NULL THEN
        RETURN json_build_object(
            'success', false, 
            'error', 'Job missing start or end time'
        );
    END IF;
    
    -- Calculate duration in minutes (rounded up)
    v_duration_minutes := CEIL(EXTRACT(EPOCH FROM (v_job_record.actual_end_time - v_job_record.actual_start_time)) / 60);
    
    -- Calculate fee: duration * hourly_rate / 60 (per minute calculation)
    v_total_fee := ROUND((v_duration_minutes * COALESCE(v_job_record.hourly_rate, 1000)) / 60.0);
    v_final_amount := v_total_fee::DECIMAL(10,2);
    
    -- Update job record with calculated values
    UPDATE jobs 
    SET 
        total_duration = v_duration_minutes,
        total_fee = v_total_fee,
        final_amount = v_final_amount,
        updated_at = NOW()
    WHERE id = p_job_id;
    
    -- Return success result
    RETURN json_build_object(
        'success', true,
        'duration_minutes', v_duration_minutes,
        'total_fee', v_total_fee,
        'final_amount', v_final_amount,
        'hourly_rate', COALESCE(v_job_record.hourly_rate, 1000)
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION calculate_and_save_job_duration_fee(UUID) TO authenticated;

-- ============================================================================
-- STEP 3: Create automatic trigger for job completion
-- ============================================================================

CREATE OR REPLACE FUNCTION auto_calculate_duration_on_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger when job status changes to completed
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        
        -- Set actual_end_time if not already set
        IF NEW.actual_end_time IS NULL THEN
            NEW.actual_end_time := NOW();
        END IF;
        
        -- Calculate and save duration if we have both start and end times
        IF NEW.actual_start_time IS NOT NULL AND NEW.actual_end_time IS NOT NULL THEN
            
            -- Calculate duration in minutes (rounded up)
            NEW.total_duration := CEIL(EXTRACT(EPOCH FROM (NEW.actual_end_time - NEW.actual_start_time)) / 60);
            
            -- Calculate fee: duration * hourly_rate / 60
            NEW.total_fee := ROUND((NEW.total_duration * COALESCE(NEW.hourly_rate, 1000)) / 60.0);
            NEW.final_amount := NEW.total_fee::DECIMAL(10,2);
            
            -- Log the calculation
            RAISE NOTICE 'Job % completed: Duration=% min, Fee=LKR %, Rate=LKR %/hr', 
                NEW.id, NEW.total_duration, NEW.total_fee, COALESCE(NEW.hourly_rate, 1000);
                
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists and create new one
DROP TRIGGER IF EXISTS auto_calculate_duration_trigger ON jobs;
CREATE TRIGGER auto_calculate_duration_trigger
    BEFORE UPDATE ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION auto_calculate_duration_on_completion();

-- ============================================================================
-- STEP 4: Create helper function to get payment details for app
-- ============================================================================

CREATE OR REPLACE FUNCTION get_job_payment_details(p_job_id UUID)
RETURNS JSON AS $$
DECLARE
    v_job RECORD;
    v_duration_text TEXT;
BEGIN
    -- Get job with calculated values
    SELECT 
        id, title, status, total_duration, total_fee, final_amount, 
        hourly_rate, actual_start_time, actual_end_time,
        helpee_id, assigned_helper_id, job_category_name
    INTO v_job
    FROM jobs 
    WHERE id = p_job_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object('error', 'Job not found');
    END IF;
    
    -- Format duration text
    IF v_job.total_duration IS NOT NULL THEN
        v_duration_text := CASE 
            WHEN v_job.total_duration >= 60 THEN 
                (v_job.total_duration / 60) || 'h ' || (v_job.total_duration % 60) || 'm'
            ELSE 
                v_job.total_duration || 'm'
        END;
    ELSE
        v_duration_text := 'Not calculated';
    END IF;
    
    -- Return formatted payment details
    RETURN json_build_object(
        'job_id', v_job.id,
        'job_title', v_job.title,
        'status', v_job.status,
        'duration_minutes', COALESCE(v_job.total_duration, 0),
        'duration_text', v_duration_text,
        'hourly_rate', COALESCE(v_job.hourly_rate, 1000.0),
        'total_fee', COALESCE(v_job.total_fee, 0),
        'final_amount', COALESCE(v_job.final_amount, 0),
        'start_time', v_job.actual_start_time,
        'end_time', v_job.actual_end_time,
        'helpee_id', v_job.helpee_id,
        'helper_id', v_job.assigned_helper_id,
        'category', COALESCE(v_job.job_category_name, 'General')
    );
    
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_job_payment_details(UUID) TO authenticated;

-- ============================================================================
-- STEP 5: Fix any existing completed jobs that don't have calculated values
-- ============================================================================

DO $$
DECLARE
    job_record RECORD;
    v_result JSON;
    fixed_count INTEGER := 0;
BEGIN
    -- Find completed jobs that don't have calculated duration
    FOR job_record IN 
        SELECT id FROM jobs 
        WHERE status = 'completed' 
        AND actual_start_time IS NOT NULL 
        AND actual_end_time IS NOT NULL 
        AND (total_duration IS NULL OR total_fee IS NULL)
    LOOP
        -- Calculate duration and fee for this job
        SELECT calculate_and_save_job_duration_fee(job_record.id) INTO v_result;
        
        IF (v_result->>'success')::boolean THEN
            fixed_count := fixed_count + 1;
            RAISE NOTICE 'Fixed job %: Duration=% min, Fee=LKR %', 
                job_record.id, 
                v_result->>'duration_minutes',
                v_result->>'total_fee';
        END IF;
    END LOOP;
    
    RAISE NOTICE '✅ Fixed % completed jobs with missing duration/fee calculations', fixed_count;
END $$;

-- ============================================================================
-- STEP 6: Verification and final report
-- ============================================================================

DO $$
DECLARE
    v_columns_count INTEGER := 0;
    v_functions_count INTEGER := 0;
    v_completed_jobs_count INTEGER := 0;
    v_calculated_jobs_count INTEGER := 0;
BEGIN
    -- Check if all columns exist
    SELECT COUNT(*) INTO v_columns_count
    FROM information_schema.columns 
    WHERE table_name = 'jobs' 
    AND column_name IN ('total_duration', 'total_fee', 'final_amount');
    
    -- Check if functions exist
    SELECT COUNT(*) INTO v_functions_count
    FROM information_schema.routines 
    WHERE routine_name IN ('calculate_and_save_job_duration_fee', 'get_job_payment_details');
    
    -- Count completed jobs
    SELECT COUNT(*) INTO v_completed_jobs_count
    FROM jobs WHERE status = 'completed';
    
    -- Count jobs with calculated values
    SELECT COUNT(*) INTO v_calculated_jobs_count
    FROM jobs 
    WHERE status = 'completed' 
    AND total_duration IS NOT NULL 
    AND total_fee IS NOT NULL;
    
    -- Report results
    RAISE NOTICE '';
    RAISE NOTICE '🎉 JOB DURATION & FEE CALCULATION FIX COMPLETED!';
    RAISE NOTICE '================================================';
    RAISE NOTICE '✅ Database Columns: % of 3 required columns added', v_columns_count;
    RAISE NOTICE '✅ Database Functions: % of 2 required functions created', v_functions_count;
    RAISE NOTICE '✅ Completed Jobs: % total', v_completed_jobs_count;
    RAISE NOTICE '✅ Jobs with Calculations: % of % completed jobs', v_calculated_jobs_count, v_completed_jobs_count;
    RAISE NOTICE '';
    RAISE NOTICE '📋 Summary:';
    RAISE NOTICE '   • total_duration column: Stores job duration in minutes';
    RAISE NOTICE '   • total_fee column: Stores calculated fee in LKR';
    RAISE NOTICE '   • final_amount column: Stores final payment amount';
    RAISE NOTICE '   • Automatic trigger: Calculates values when job is completed';
    RAISE NOTICE '   • Helper functions: Available for manual calculations';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Your app now properly calculates and displays job duration and fees!';
    
    -- Verify everything is working
    IF v_columns_count = 3 AND v_functions_count = 2 THEN
        RAISE NOTICE '✅ ALL SYSTEMS READY - Job duration and fee calculation is fully functional!';
    ELSE
        RAISE EXCEPTION '❌ Setup incomplete - Please check the errors above';
    END IF;
    
END $$;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================ 