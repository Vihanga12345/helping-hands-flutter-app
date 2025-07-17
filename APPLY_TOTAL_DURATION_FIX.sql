-- ============================================================================
-- COMPREHENSIVE TIME TRACKING FIX FOR HELPING HANDS APP
-- ============================================================================
-- Execute this in Supabase SQL Editor to fix all time tracking issues
-- Date: January 2025

-- ============================================================================
-- STEP 1: Add total_duration column to jobs table
-- ============================================================================

-- Add total_duration column to store calculated job duration in minutes
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' AND column_name = 'total_duration'
    ) THEN
        ALTER TABLE public.jobs ADD COLUMN total_duration INTEGER DEFAULT NULL;
        RAISE NOTICE '✅ Added total_duration column to jobs table';
    ELSE
        RAISE NOTICE 'ℹ️  total_duration column already exists in jobs table';
    END IF;
END $$;

-- Add comment for clarity
COMMENT ON COLUMN jobs.total_duration IS 'Total duration of the job in minutes, calculated from actual_start_time and actual_end_time';

-- Create index for performance when querying by duration
CREATE INDEX IF NOT EXISTS idx_jobs_total_duration ON jobs(total_duration) WHERE total_duration IS NOT NULL;

-- ============================================================================
-- STEP 2: Add total_fee column to store calculated fees
-- ============================================================================

-- Add total_fee column to store calculated job fees
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' AND column_name = 'total_fee'
    ) THEN
        ALTER TABLE public.jobs ADD COLUMN total_fee INTEGER DEFAULT NULL;
        RAISE NOTICE '✅ Added total_fee column to jobs table';
    ELSE
        RAISE NOTICE 'ℹ️  total_fee column already exists in jobs table';
    END IF;
END $$;

-- Add comment for clarity
COMMENT ON COLUMN jobs.total_fee IS 'Total calculated fee in LKR, calculated as (total_duration * hourly_rate / 60)';

-- ============================================================================
-- STEP 3: Ensure final_amount column exists for payment display
-- ============================================================================

-- Add final_amount column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' AND column_name = 'final_amount'
    ) THEN
        ALTER TABLE public.jobs ADD COLUMN final_amount DECIMAL(10,2) DEFAULT NULL;
        RAISE NOTICE '✅ Added final_amount column to jobs table';
    ELSE
        RAISE NOTICE 'ℹ️  final_amount column already exists in jobs table';
    END IF;
END $$;

-- ============================================================================
-- STEP 4: Create function to calculate job duration and fee
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_and_save_job_duration_fee(p_job_id UUID)
RETURNS JSON AS $$
DECLARE
    v_job_record RECORD;
    v_duration_minutes INTEGER;
    v_total_fee INTEGER;
    v_final_amount DECIMAL(10,2);
    v_result JSON;
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
    
    -- Calculate duration in minutes
    v_duration_minutes := EXTRACT(EPOCH FROM (v_job_record.actual_end_time - v_job_record.actual_start_time)) / 60;
    
    -- Calculate fee (per minute)
    v_total_fee := (v_duration_minutes * COALESCE(v_job_record.hourly_rate, 1000)) / 60;
    v_final_amount := v_total_fee::DECIMAL(10,2);
    
    -- Update job record
    UPDATE jobs 
    SET 
        total_duration = v_duration_minutes,
        total_fee = v_total_fee,
        final_amount = v_final_amount,
        updated_at = NOW()
    WHERE id = p_job_id;
    
    -- Return result
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION calculate_and_save_job_duration_fee(UUID) TO authenticated;

-- ============================================================================
-- STEP 5: Create trigger to automatically calculate duration on job completion
-- ============================================================================

CREATE OR REPLACE FUNCTION auto_calculate_duration_on_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger when job status changes to completed
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Set actual_end_time if not already set
        IF NEW.actual_end_time IS NULL THEN
            NEW.actual_end_time := NOW();
        END IF;
        
        -- Calculate and save duration if we have both start and end times
        IF NEW.actual_start_time IS NOT NULL AND NEW.actual_end_time IS NOT NULL THEN
            -- Calculate duration in minutes
            NEW.total_duration := EXTRACT(EPOCH FROM (NEW.actual_end_time - NEW.actual_start_time)) / 60;
            
            -- Calculate fee (per minute)
            NEW.total_fee := (NEW.total_duration * COALESCE(NEW.hourly_rate, 1000)) / 60;
            NEW.final_amount := NEW.total_fee::DECIMAL(10,2);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS auto_calculate_duration_trigger ON jobs;

-- Create the trigger
CREATE TRIGGER auto_calculate_duration_trigger
    BEFORE UPDATE ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION auto_calculate_duration_on_completion();

-- ============================================================================
-- STEP 6: Verification and status report
-- ============================================================================

-- Check if all required columns exist
DO $$
DECLARE
    v_columns_exist BOOLEAN := true;
    v_missing_columns TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Check total_duration column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' AND column_name = 'total_duration'
    ) THEN
        v_columns_exist := false;
        v_missing_columns := array_append(v_missing_columns, 'total_duration');
    END IF;
    
    -- Check total_fee column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' AND column_name = 'total_fee'
    ) THEN
        v_columns_exist := false;
        v_missing_columns := array_append(v_missing_columns, 'total_fee');
    END IF;
    
    -- Check final_amount column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' AND column_name = 'final_amount'
    ) THEN
        v_columns_exist := false;
        v_missing_columns := array_append(v_missing_columns, 'final_amount');
    END IF;
    
    -- Report results
    IF v_columns_exist THEN
        RAISE NOTICE '✅ SUCCESS: All required time tracking columns exist in jobs table';
    ELSE
        RAISE EXCEPTION '❌ FAILED: Missing columns in jobs table: %', array_to_string(v_missing_columns, ', ');
    END IF;
END $$;

-- ============================================================================
-- FINAL SUCCESS MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🎉 DATABASE MIGRATION COMPLETED SUCCESSFULLY!';
    RAISE NOTICE '📋 Summary of changes:';
    RAISE NOTICE '   ✅ Added total_duration column to jobs table';
    RAISE NOTICE '   ✅ Added total_fee column to jobs table';
    RAISE NOTICE '   ✅ Added final_amount column to jobs table';
    RAISE NOTICE '   ✅ Created calculate_and_save_job_duration_fee function';
    RAISE NOTICE '   ✅ Created auto-calculation trigger for job completion';
    RAISE NOTICE '   ✅ Added performance indexes for time tracking queries';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Your app can now properly track job duration and calculate fees!';
END $$; 