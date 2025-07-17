-- Drop existing function
DROP FUNCTION IF EXISTS initiate_cash_payment_confirmation(uuid);

-- Recreate with consistent integer success field
CREATE OR REPLACE FUNCTION initiate_cash_payment_confirmation(job_id_param uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    job_record record;
    payment_record record;
    result jsonb;
BEGIN
    -- Get job details with user information
    SELECT 
        j.*,
        helpee.id as helpee_id,
        helpee.first_name as helpee_first_name,
        helpee.last_name as helpee_last_name,
        helper.id as helper_id,
        helper.first_name as helper_first_name,
        helper.last_name as helper_last_name,
        COALESCE(j.final_amount, j.estimated_amount) as payment_amount
    INTO job_record
    FROM jobs j
    JOIN users helpee ON j.helpee_id = helpee.id
    JOIN users helper ON j.helper_id = helper.id
    WHERE j.id = job_id_param;

    -- Check if job exists
    IF job_record IS NULL THEN
        RETURN jsonb_build_object(
            'success', 0,
            'message', 'Job not found'
        );
    END IF;

    -- Check if job is completed
    IF job_record.status != 'completed' THEN
        RETURN jsonb_build_object(
            'success', 0,
            'message', 'Job is not completed'
        );
    END IF;

    -- Check if payment is already confirmed
    SELECT * INTO payment_record
    FROM payment_confirmations
    WHERE job_id = job_id_param;

    IF payment_record IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', 0,
            'message', 'Payment already confirmed'
        );
    END IF;

    -- Build response with job and user details
    result := jsonb_build_object(
        'success', 1,
        'job_id', job_record.id,
        'helpee_id', job_record.helpee_id,
        'helpee_first_name', job_record.helpee_first_name,
        'helpee_last_name', job_record.helpee_last_name,
        'helper_id', job_record.helper_id,
        'helper_first_name', job_record.helper_first_name,
        'helper_last_name', job_record.helper_last_name,
        'payment_amount', job_record.payment_amount,
        'payment_type', 'cash',
        'status', job_record.status
    );

    RETURN result;
END;
$$; 