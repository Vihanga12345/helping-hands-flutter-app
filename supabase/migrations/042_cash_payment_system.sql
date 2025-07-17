-- ============================================================================
-- Migration 042: Cash Payment System Implementation
-- Date: January 2025
-- Purpose: Implement cash-only payment system with dual confirmation flow
--          where both helpee and helper must confirm cash payment
-- ============================================================================

-- Add payment confirmation tracking columns to jobs table
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS payment_amount_calculated DECIMAL(10,2);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helpee_payment_confirmed BOOLEAN DEFAULT false;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS helper_payment_received BOOLEAN DEFAULT false;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS payment_confirmed_at TIMESTAMP;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS payment_dispute_reported BOOLEAN DEFAULT false;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS payment_method VARCHAR(20) DEFAULT 'cash';

-- Create payment confirmations table for tracking all payment events
CREATE TABLE IF NOT EXISTS payment_confirmations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id),
    user_id UUID NOT NULL REFERENCES users(id),
    confirmation_type VARCHAR(20) NOT NULL CHECK (confirmation_type IN ('payment_made', 'payment_received', 'dispute_reported')),
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) DEFAULT 'cash',
    confirmed_at TIMESTAMP DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create payment disputes table for handling payment issues
CREATE TABLE IF NOT EXISTS payment_disputes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id),
    reporter_id UUID NOT NULL REFERENCES users(id),
    dispute_type VARCHAR(50) NOT NULL,
    dispute_description TEXT NOT NULL,
    amount_disputed DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'closed')),
    admin_notes TEXT,
    resolution_details TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP
);

-- Function to calculate payment amount based on job duration and hourly rate
CREATE OR REPLACE FUNCTION calculate_job_payment_amount(job_id_param UUID)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    total_seconds INTEGER;
    hourly_rate DECIMAL(10,2);
    calculated_amount DECIMAL(10,2);
BEGIN
    -- Get the total elapsed time and hourly rate
    SELECT 
        calculate_job_elapsed_time(job_id_param),
        COALESCE(j.hourly_rate, 1000.00) -- Default rate if not set
    INTO total_seconds, hourly_rate
    FROM jobs j
    WHERE j.id = job_id_param;
    
    -- Calculate payment: (total_seconds / 3600) * hourly_rate
    calculated_amount := ROUND((total_seconds::DECIMAL / 3600.0) * hourly_rate, 2);
    
    -- Minimum payment of 1 hour even for shorter jobs
    IF calculated_amount < hourly_rate THEN
        calculated_amount := hourly_rate;
    END IF;
    
    RETURN calculated_amount;
END;
$$ LANGUAGE plpgsql;

-- Function to initiate cash payment confirmation process
CREATE OR REPLACE FUNCTION initiate_cash_payment_confirmation(job_id_param UUID)
RETURNS JSON AS $$
DECLARE
    job_record RECORD;
    payment_amount DECIMAL(10,2);
    result JSON;
BEGIN
    -- Get job details
    SELECT j.*, u1.name as helpee_name, u2.name as helper_name
    FROM jobs j
    JOIN users u1 ON j.helpee_id = u1.id
    LEFT JOIN users u2 ON j.assigned_helper_id = u2.id
    WHERE j.id = job_id_param
    INTO job_record;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Job not found');
    END IF;
    
    IF job_record.status != 'completed' THEN
        RETURN json_build_object('success', false, 'error', 'Job must be completed before payment');
    END IF;
    
    -- Calculate payment amount
    payment_amount := calculate_job_payment_amount(job_id_param);
    
    -- Update job with calculated payment amount
    UPDATE jobs 
    SET payment_amount_calculated = payment_amount
    WHERE id = job_id_param;
    
    -- Return payment details
    result := json_build_object(
        'success', true,
        'job_id', job_id_param,
        'payment_amount', payment_amount,
        'helpee_name', job_record.helpee_name,
        'helper_name', job_record.helper_name,
        'job_title', job_record.title,
        'hourly_rate', job_record.hourly_rate,
        'total_hours', ROUND((SELECT calculate_job_elapsed_time(job_id_param))::DECIMAL / 3600.0, 2)
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to confirm helpee payment (helpee says "I paid")
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
    
    payment_amount := job_record.payment_amount_calculated;
    
    -- Update job
    UPDATE jobs 
    SET helpee_payment_confirmed = true
    WHERE id = job_id_param;
    
    -- Record payment confirmation
    INSERT INTO payment_confirmations (job_id, user_id, confirmation_type, amount, notes)
    VALUES (job_id_param, helpee_id_param, 'payment_made', payment_amount, notes_param);
    
    RETURN json_build_object('success', true, 'message', 'Payment confirmed by helpee');
END;
$$ LANGUAGE plpgsql;

-- Function to confirm helper received payment (helper says "I received payment")
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
    
    payment_amount := job_record.payment_amount_calculated;
    
    -- Update job
    UPDATE jobs 
    SET 
        helper_payment_received = true,
        payment_confirmed_at = NOW(),
        status = 'payment_confirmed'
    WHERE id = job_id_param;
    
    -- Record payment confirmation
    INSERT INTO payment_confirmations (job_id, user_id, confirmation_type, amount, notes)
    VALUES (job_id_param, helper_id_param, 'payment_received', payment_amount, notes_param);
    
    RETURN json_build_object('success', true, 'message', 'Payment fully confirmed. Job complete!');
END;
$$ LANGUAGE plpgsql;

-- Function to report payment dispute
CREATE OR REPLACE FUNCTION report_payment_dispute(
    job_id_param UUID, 
    reporter_id_param UUID, 
    dispute_type_param VARCHAR(50), 
    description_param TEXT,
    amount_disputed_param DECIMAL(10,2) DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    job_record RECORD;
BEGIN
    -- Verify user is involved in this job
    SELECT * FROM jobs 
    WHERE id = job_id_param 
    AND (helpee_id = reporter_id_param OR assigned_helper_id = reporter_id_param)
    INTO job_record;
    
    IF NOT FOUND THEN
        RETURN json_build_object('success', false, 'error', 'Unauthorized or job not found');
    END IF;
    
    -- Update job dispute status
    UPDATE jobs 
    SET payment_dispute_reported = true
    WHERE id = job_id_param;
    
    -- Create dispute record
    INSERT INTO payment_disputes (
        job_id, 
        reporter_id, 
        dispute_type, 
        dispute_description, 
        amount_disputed
    ) VALUES (
        job_id_param, 
        reporter_id_param, 
        dispute_type_param, 
        description_param, 
        COALESCE(amount_disputed_param, job_record.payment_amount_calculated)
    );
    
    -- Record in payment confirmations
    INSERT INTO payment_confirmations (job_id, user_id, confirmation_type, amount, notes)
    VALUES (job_id_param, reporter_id_param, 'dispute_reported', 
            COALESCE(amount_disputed_param, job_record.payment_amount_calculated), 
            dispute_type_param || ': ' || description_param);
    
    RETURN json_build_object('success', true, 'message', 'Payment dispute reported successfully');
END;
$$ LANGUAGE plpgsql;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_payment_confirmations_job_id ON payment_confirmations(job_id);
CREATE INDEX IF NOT EXISTS idx_payment_confirmations_user_id ON payment_confirmations(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_disputes_job_id ON payment_disputes(job_id);
CREATE INDEX IF NOT EXISTS idx_payment_disputes_status ON payment_disputes(status);
CREATE INDEX IF NOT EXISTS idx_jobs_payment_status ON jobs(helpee_payment_confirmed, helper_payment_received);

-- ✅ Cash payment system migration completed! 