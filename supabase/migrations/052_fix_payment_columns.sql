-- Fix Payment System - Add Missing Columns and Fix Amount Issues
-- Migration: 052_fix_payment_columns.sql

-- Add missing payment columns to jobs table
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS helpee_payment_confirmed_at TIMESTAMPTZ DEFAULT NULL,
ADD COLUMN IF NOT EXISTS helper_payment_received_at TIMESTAMPTZ DEFAULT NULL,
ADD COLUMN IF NOT EXISTS payment_amount_calculated DECIMAL(10,2) DEFAULT NULL;

-- Update payment confirmation functions to set timestamp columns properly
CREATE OR REPLACE FUNCTION confirm_helpee_payment(job_id_param UUID, helpee_id_param UUID, notes_param TEXT DEFAULT '')
RETURNS JSON AS $$
DECLARE
    job_record RECORD;
    payment_amount DECIMAL(10,2);
BEGIN
    -- Verify job and helpee
    SELECT * FROM jobs WHERE id = job_id_param AND helpee_id = helpee_id_param INTO job_record;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Unauthorized or job not found');
    END IF;
    
    IF job_record.helpee_payment_confirmed THEN
        RETURN json_build_object('success', false, 'error', 'Payment already confirmed by helpee');
    END IF;
    
    -- Calculate payment amount if not already calculated
    IF job_record.payment_amount_calculated IS NULL THEN
        payment_amount := calculate_job_payment_amount(job_id_param);
        
        -- Update the calculated amount
        UPDATE jobs 
        SET payment_amount_calculated = payment_amount
        WHERE id = job_id_param;
    ELSE
        payment_amount := job_record.payment_amount_calculated;
    END IF;
    
    -- Update job with confirmation timestamp
    UPDATE jobs 
    SET 
        helpee_payment_confirmed = true,
        helpee_payment_confirmed_at = NOW()
    WHERE id = job_id_param;
    
    -- Record payment confirmation with proper amount
    INSERT INTO payment_confirmations (job_id, user_id, confirmation_type, amount, payment_method, notes)
    VALUES (job_id_param, helpee_id_param, 'payment_made', payment_amount, 'cash', notes_param);
    
    RETURN json_build_object('success', true, 'message', 'Payment confirmed by helpee');
END;
$$ LANGUAGE plpgsql;

-- Update helper payment confirmation function
CREATE OR REPLACE FUNCTION confirm_helper_payment_received(job_id_param UUID, helper_id_param UUID, notes_param TEXT DEFAULT '')
RETURNS JSON AS $$
DECLARE
    job_record RECORD;
    payment_amount DECIMAL(10,2);
BEGIN
    -- Verify job and helper
    SELECT * FROM jobs WHERE id = job_id_param AND assigned_helper_id = helper_id_param INTO job_record;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Unauthorized or job not found');
    END IF;
    
    IF job_record.helper_payment_received THEN
        RETURN json_build_object('success', false, 'error', 'Payment receipt already confirmed by helper');
    END IF;
    
    IF NOT job_record.helpee_payment_confirmed THEN
        RETURN json_build_object('success', false, 'error', 'Helpee must confirm payment first');
    END IF;
    
    -- Calculate payment amount if not already calculated
    IF job_record.payment_amount_calculated IS NULL THEN
        payment_amount := calculate_job_payment_amount(job_id_param);
        
        -- Update the calculated amount
        UPDATE jobs 
        SET payment_amount_calculated = payment_amount
        WHERE id = job_id_param;
    ELSE
        payment_amount := job_record.payment_amount_calculated;
    END IF;
    
    -- Update job with confirmation timestamp
    UPDATE jobs 
    SET 
        helper_payment_received = true,
        helper_payment_received_at = NOW(),
        payment_confirmed_at = NOW(),
        status = 'payment_confirmed'
    WHERE id = job_id_param;
    
    -- Record payment confirmation with proper amount
    INSERT INTO payment_confirmations (job_id, user_id, confirmation_type, amount, payment_method, notes)
    VALUES (job_id_param, helper_id_param, 'payment_received', payment_amount, 'cash', notes_param);
    
    RETURN json_build_object('success', true, 'message', 'Payment fully confirmed. Job complete!');
END;
$$ LANGUAGE plpgsql;

-- Update existing jobs to have calculated payment amounts for completed jobs
UPDATE jobs 
SET payment_amount_calculated = calculate_job_payment_amount(id)
WHERE status = 'completed' AND payment_amount_calculated IS NULL;

-- ✅ Payment columns and functions fixed! 