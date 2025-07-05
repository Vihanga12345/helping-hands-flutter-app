-- HELPING HANDS APP - FIX JOB EDIT ISSUES
-- ============================================================================
-- Migration 008: Fix Job Edit Issues and Database Schema Inconsistencies
-- This fixes the column missing errors and job edit functionality issues

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- STEP 1: Fix job_question_answers table structure
-- ============================================================================

-- Add missing columns that the app expects to exist
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer_number DECIMAL(10,2);
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer_date DATE;
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer_time TIME;
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer_boolean BOOLEAN;
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS selected_options JSONB;

-- Ensure the table has the correct structure
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- ============================================================================
-- STEP 2: Fix job_category_questions table structure
-- ============================================================================

-- Ensure question column exists (some migrations use question_text)
ALTER TABLE job_category_questions ADD COLUMN IF NOT EXISTS question TEXT;

-- Sync question column with question_text if needed
UPDATE job_category_questions 
SET question = question_text 
WHERE question IS NULL AND question_text IS NOT NULL;

UPDATE job_category_questions 
SET question_text = question 
WHERE question_text IS NULL AND question IS NOT NULL;

-- Add missing columns for job category questions
ALTER TABLE job_category_questions ADD COLUMN IF NOT EXISTS options JSONB;
ALTER TABLE job_category_questions ADD COLUMN IF NOT EXISTS placeholder_text TEXT;
ALTER TABLE job_category_questions ADD COLUMN IF NOT EXISTS validation_rules JSONB;

-- ============================================================================
-- STEP 3: Fix jobs table for better edit support
-- ============================================================================

-- Add notes column if missing (for additional notes/description)
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS notes TEXT;

-- Ensure description column exists and is properly set up
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS description TEXT;

-- Create a function to sync notes and description
CREATE OR REPLACE FUNCTION sync_job_description()
RETURNS TRIGGER AS $$
BEGIN
    -- If description is updated and notes is empty, copy to notes
    IF NEW.description IS DISTINCT FROM OLD.description AND (NEW.notes IS NULL OR NEW.notes = '') THEN
        NEW.notes = NEW.description;
    END IF;
    
    -- If notes is updated and description is empty, copy to description
    IF NEW.notes IS DISTINCT FROM OLD.notes AND (NEW.description IS NULL OR NEW.description = '') THEN
        NEW.description = NEW.notes;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for syncing job description and notes
DROP TRIGGER IF EXISTS sync_job_description_trigger ON jobs;
CREATE TRIGGER sync_job_description_trigger 
    BEFORE UPDATE ON jobs 
    FOR EACH ROW 
    EXECUTE FUNCTION sync_job_description();

-- ============================================================================
-- STEP 4: Ensure proper foreign key relationships
-- ============================================================================

-- Make sure job_question_answers references are correct
ALTER TABLE job_question_answers DROP CONSTRAINT IF EXISTS job_question_answers_question_id_fkey;
ALTER TABLE job_question_answers ADD CONSTRAINT job_question_answers_question_id_fkey 
    FOREIGN KEY (question_id) REFERENCES job_category_questions(id) ON DELETE CASCADE;

-- Ensure unique constraint exists
ALTER TABLE job_question_answers DROP CONSTRAINT IF EXISTS unique_job_question;
ALTER TABLE job_question_answers ADD CONSTRAINT unique_job_question 
    UNIQUE (job_id, question_id);

-- ============================================================================
-- STEP 5: Fix category_id column references in jobs table
-- ============================================================================

-- Ensure category_id column exists and is properly referenced
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS category_id UUID;

-- Add foreign key constraint if missing
ALTER TABLE jobs DROP CONSTRAINT IF EXISTS jobs_category_id_fkey;
ALTER TABLE jobs ADD CONSTRAINT jobs_category_id_fkey 
    FOREIGN KEY (category_id) REFERENCES job_categories(id);

-- ============================================================================
-- STEP 6: Create improved views for job data with proper joins
-- ============================================================================

-- Create a comprehensive view for job details with all needed data
CREATE OR REPLACE VIEW job_details_with_questions AS
SELECT 
    j.id,
    j.helpee_id,
    j.assigned_helper_id,
    j.category_id,
    j.title,
    j.description,
    j.notes,
    j.special_instructions,
    j.job_type,
    j.is_private,
    j.status,
    j.hourly_rate,
    j.scheduled_date,
    j.scheduled_start_time,
    j.scheduled_time,
    j.location_address,
    j.location_latitude,
    j.location_longitude,
    j.created_at,
    j.updated_at,
    jc.name as category_name,
    jc.description as category_description,
    -- Aggregate questions and answers
    COALESCE(
        JSON_AGG(
            JSON_BUILD_OBJECT(
                'question_id', jcq.id,
                'question', jcq.question,
                'question_type', jcq.question_type,
                'is_required', jcq.is_required,
                'answer_text', jqa.answer_text,
                'answer_number', jqa.answer_number,
                'answer_date', jqa.answer_date,
                'answer_time', jqa.answer_time,
                'answer_boolean', jqa.answer_boolean,
                'selected_options', jqa.selected_options
            ) ORDER BY jcq.order_index, jcq.question_order
        ) FILTER (WHERE jcq.id IS NOT NULL),
        '[]'::json
    ) as questions_and_answers
FROM jobs j
LEFT JOIN job_categories jc ON j.category_id = jc.id
LEFT JOIN job_category_questions jcq ON jc.id = jcq.category_id
LEFT JOIN job_question_answers jqa ON j.id = jqa.job_id AND jcq.id = jqa.question_id
GROUP BY j.id, j.helpee_id, j.assigned_helper_id, j.category_id, j.title, j.description, 
         j.notes, j.special_instructions, j.job_type, j.is_private, j.status, j.hourly_rate,
         j.scheduled_date, j.scheduled_start_time, j.scheduled_time, j.location_address,
         j.location_latitude, j.location_longitude, j.created_at, j.updated_at,
         jc.name, jc.description;

-- ============================================================================
-- STEP 7: Create function to handle job updates with questions
-- ============================================================================

CREATE OR REPLACE FUNCTION update_job_with_questions(
    p_job_id UUID,
    p_title VARCHAR(200),
    p_description TEXT,
    p_category_id UUID,
    p_hourly_rate DECIMAL(10,2),
    p_scheduled_date DATE,
    p_scheduled_time TIME,
    p_location_address TEXT,
    p_is_private BOOLEAN,
    p_notes TEXT,
    p_question_answers JSONB DEFAULT '[]'::jsonb
) RETURNS BOOLEAN AS $$
DECLARE
    question_answer JSONB;
BEGIN
    -- Update the main job record
    UPDATE jobs SET
        title = p_title,
        description = p_description,
        notes = p_notes,
        category_id = p_category_id,
        hourly_rate = p_hourly_rate,
        scheduled_date = p_scheduled_date,
        scheduled_time = p_scheduled_time,
        scheduled_start_time = p_scheduled_time,
        location_address = p_location_address,
        is_private = p_is_private,
        job_type = CASE WHEN p_is_private THEN 'private' ELSE 'public' END,
        updated_at = NOW()
    WHERE id = p_job_id;
    
    -- Delete existing question answers for this job
    DELETE FROM job_question_answers WHERE job_id = p_job_id;
    
    -- Insert new question answers
    FOR question_answer IN SELECT jsonb_array_elements(p_question_answers)
    LOOP
        INSERT INTO job_question_answers (
            job_id,
            question_id,
            answer_text,
            answer_number,
            answer_date,
            answer_time,
            answer_boolean,
            selected_options
        ) VALUES (
            p_job_id,
            (question_answer->>'question_id')::UUID,
            question_answer->>'answer_text',
            CASE WHEN question_answer->>'answer_number' IS NOT NULL 
                 THEN (question_answer->>'answer_number')::DECIMAL(10,2) 
                 ELSE NULL END,
            CASE WHEN question_answer->>'answer_date' IS NOT NULL 
                 THEN (question_answer->>'answer_date')::DATE 
                 ELSE NULL END,
            CASE WHEN question_answer->>'answer_time' IS NOT NULL 
                 THEN (question_answer->>'answer_time')::TIME 
                 ELSE NULL END,
            CASE WHEN question_answer->>'answer_boolean' IS NOT NULL 
                 THEN (question_answer->>'answer_boolean')::BOOLEAN 
                 ELSE NULL END,
            question_answer->'selected_options'
        );
    END LOOP;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 8: Add indexes for better performance
-- ============================================================================

-- Add indexes for the new columns
CREATE INDEX IF NOT EXISTS idx_job_question_answers_job_question ON job_question_answers(job_id, question_id);
CREATE INDEX IF NOT EXISTS idx_jobs_category_id ON jobs(category_id);
CREATE INDEX IF NOT EXISTS idx_job_category_questions_category_order ON job_category_questions(category_id, order_index);
CREATE INDEX IF NOT EXISTS idx_job_category_questions_category_question_order ON job_category_questions(category_id, question_order);

-- ============================================================================
-- STEP 9: Update existing data to ensure consistency
-- ============================================================================

-- Ensure all jobs have proper category relationships
UPDATE jobs 
SET category_id = jc.id 
FROM job_categories jc 
WHERE jobs.category_id IS NULL 
AND jc.name = 'House Cleaning' -- Default category for jobs without category
AND jobs.category_id IS NULL;

-- Ensure notes field is populated from description if empty
UPDATE jobs 
SET notes = description 
WHERE (notes IS NULL OR notes = '') 
AND description IS NOT NULL 
AND description != '';

-- Ensure description field is populated from notes if empty
UPDATE jobs 
SET description = notes 
WHERE (description IS NULL OR description = '') 
AND notes IS NOT NULL 
AND notes != '';

-- Ensure is_private is set based on job_type
UPDATE jobs 
SET is_private = (job_type = 'private') 
WHERE is_private IS NULL;

-- Ensure job_type is set based on is_private
UPDATE jobs 
SET job_type = CASE WHEN is_private THEN 'private' ELSE 'public' END 
WHERE job_type IS NULL;

-- ============================================================================
-- STEP 10: Add triggers for data consistency
-- ============================================================================

-- Trigger to update updated_at on job_question_answers
CREATE OR REPLACE FUNCTION update_job_question_answers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_job_question_answers_updated_at_trigger ON job_question_answers;
CREATE TRIGGER update_job_question_answers_updated_at_trigger
    BEFORE UPDATE ON job_question_answers
    FOR EACH ROW
    EXECUTE FUNCTION update_job_question_answers_updated_at();

-- ============================================================================
-- STEP 11: Verification queries
-- ============================================================================

-- Check if all required columns exist
DO $$
BEGIN
    -- Check job_question_answers columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'job_question_answers' AND column_name = 'answer_number') THEN
        RAISE EXCEPTION 'Column answer_number missing from job_question_answers';
    END IF;
    
    -- Check jobs columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'jobs' AND column_name = 'notes') THEN
        RAISE EXCEPTION 'Column notes missing from jobs';
    END IF;
    
    -- Check job_category_questions columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'job_category_questions' AND column_name = 'question') THEN
        RAISE EXCEPTION 'Column question missing from job_category_questions';
    END IF;
    
    RAISE NOTICE 'All required columns exist successfully';
END
$$;

-- Check data consistency
SELECT 
    'Data consistency check' as status,
    COUNT(*) as total_jobs,
    COUNT(CASE WHEN category_id IS NOT NULL THEN 1 END) as jobs_with_category,
    COUNT(CASE WHEN description IS NOT NULL AND description != '' THEN 1 END) as jobs_with_description,
    COUNT(CASE WHEN notes IS NOT NULL AND notes != '' THEN 1 END) as jobs_with_notes
FROM jobs;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Summary of changes:
-- 1. Added missing columns to job_question_answers (answer_number, answer_date, answer_time, answer_boolean, selected_options)
-- 2. Fixed job_category_questions structure (question column)
-- 3. Enhanced jobs table with notes column and proper syncing
-- 4. Created comprehensive view for job details with questions
-- 5. Added function for updating jobs with questions
-- 6. Added proper indexes and constraints
-- 7. Updated existing data for consistency
-- 8. Added triggers for data integrity

-- Next steps for the Flutter app:
-- 1. Update job edit functionality to use the new update_job_with_questions function
-- 2. Ensure proper data mapping in the app when loading job details
-- 3. Test job editing with the new database structure 