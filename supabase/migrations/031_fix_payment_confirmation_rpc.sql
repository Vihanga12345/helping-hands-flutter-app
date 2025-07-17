DROP FUNCTION IF EXISTS initiate_cash_payment_confirmation(uuid);

CREATE OR REPLACE FUNCTION initiate_cash_payment_confirmation(job_id_param uuid)
RETURNS TABLE (
  success boolean,
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
BEGIN
  -- Get job details
  SELECT * INTO job_record FROM jobs WHERE id = job_id_param;
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Job not found', 0::numeric, NULL, NULL, NULL, NULL, NULL, NULL;
    RETURN;
  END IF;

  -- Calculate payment amount
  calculated_amount := (job_record.total_time_seconds / 3600.0) * job_record.hourly_rate;
  IF calculated_amount < job_record.hourly_rate THEN
    calculated_amount := job_record.hourly_rate;
  END IF;

  -- Update job with calculated amount
  UPDATE jobs
  SET payment_amount_calculated = calculated_amount
  WHERE id = job_id_param;

  -- Get helpee details
  SELECT u.id, u.first_name, u.last_name INTO helpee_record FROM users u WHERE u.id = job_record.helpee_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Helpee not found', 0::numeric, NULL, NULL, NULL, NULL, NULL, NULL;
    RETURN;
  END IF;
  
  -- Get helper details
  SELECT u.id, u.first_name, u.last_name INTO helper_record FROM users u WHERE u.id = job_record.assigned_helper_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Helper not found', 0::numeric, NULL, NULL, NULL, NULL, NULL, NULL;
    RETURN;
  END IF;

  RETURN QUERY SELECT
    true AS success,
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
    RETURN QUERY SELECT false, SQLERRM, 0::numeric, NULL, NULL, NULL, NULL, NULL, NULL;
END;
$$ LANGUAGE plpgsql; 