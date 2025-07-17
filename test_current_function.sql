-- Test the current function output
SELECT * FROM get_public_jobs_for_helper('29e2adb3-4910-4c83-804b-0014b1c4598a');

-- Check helper's active categories  
SELECT hjt.is_active, jc.name as category_name 
FROM helper_job_types hjt 
JOIN job_categories jc ON hjt.job_category_id = jc.id 
WHERE hjt.helper_id = '29e2adb3-4910-4c83-804b-0014b1c4598a';

-- Check all pending jobs
SELECT id, title, job_category_name, category_id 
FROM jobs 
WHERE status = 'pending' AND is_private = false; 