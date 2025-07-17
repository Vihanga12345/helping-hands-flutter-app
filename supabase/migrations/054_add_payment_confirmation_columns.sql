-- Add Payment Confirmation Columns
-- Migration: 054_add_payment_confirmation_columns.sql
-- Purpose: Add boolean columns to track payment confirmation from both helper and helpee

-- Add payment confirmation columns to jobs table
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS helper_payment_confirmation BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS helpee_payment_confirmation BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS payment_confirmation_completed_at TIMESTAMPTZ DEFAULT NULL;

-- Create index for payment confirmation queries
CREATE INDEX IF NOT EXISTS idx_jobs_payment_confirmations ON jobs(helper_payment_confirmation, helpee_payment_confirmation);

-- Update existing jobs to match current payment confirmation logic
-- If helper_payment_received is true, set helper_payment_confirmation to true
UPDATE jobs 
SET helper_payment_confirmation = helper_payment_received
WHERE helper_payment_received IS NOT NULL;

-- If helpee_payment_confirmed is true, set helpee_payment_confirmation to true
UPDATE jobs 
SET helpee_payment_confirmation = helpee_payment_confirmed
WHERE helpee_payment_confirmed IS NOT NULL;

-- Set payment_confirmation_completed_at if both confirmations are true
UPDATE jobs 
SET payment_confirmation_completed_at = NOW()
WHERE helper_payment_confirmation = TRUE 
AND helpee_payment_confirmation = TRUE 
AND payment_confirmation_completed_at IS NULL;

-- Add comment for documentation
COMMENT ON COLUMN jobs.helper_payment_confirmation IS 'Helper confirms they received payment (TRUE) or not (FALSE)';
COMMENT ON COLUMN jobs.helpee_payment_confirmation IS 'Helpee confirms they paid (TRUE) or not (FALSE)';
COMMENT ON COLUMN jobs.payment_confirmation_completed_at IS 'Timestamp when both parties confirmed payment';

-- ✅ Payment confirmation columns added successfully! 