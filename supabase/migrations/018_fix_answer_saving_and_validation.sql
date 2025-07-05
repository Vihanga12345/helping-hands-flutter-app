-- HELPING HANDS APP - Fix Answer Saving and Validation
-- ============================================================================
-- Migration 018: Fix job question answer saving and ensure hourly rate structure
-- Date: January 2025
-- Purpose: Fix answer saving issues and add hourly rate validation

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- STEP 1: Fix Job Question Answers Table Structure
-- ============================================================================

-- Ensure all required columns exist in job_question_answers
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer TEXT;
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer_text TEXT;
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer_number DECIMAL(10,2);
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer_date DATE;
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer_time TIME;
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS answer_boolean BOOLEAN;
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS selected_options JSONB;
ALTER TABLE job_question_answers ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- ============================================================================
-- STEP 2: Create Trigger to Sync Answer Fields
-- ============================================================================

-- Function to sync answer fields automatically
CREATE OR REPLACE FUNCTION sync_job_question_answers()
RETURNS TRIGGER AS $$
DECLARE
    q_type VARCHAR(50);
BEGIN
    -- Set updated_at timestamp
    NEW.updated_at = NOW();
    
    -- When type-specific columns are updated, update main answer column
    IF NEW.answer_text IS NOT NULL AND NEW.answer_text != '' THEN
        NEW.answer = NEW.answer_text;
    ELSIF NEW.answer_number IS NOT NULL THEN
        NEW.answer = NEW.answer_number::TEXT;
    ELSIF NEW.answer_boolean IS NOT NULL THEN
        NEW.answer = CASE WHEN NEW.answer_boolean THEN 'Yes' ELSE 'No' END;
    ELSIF NEW.answer_date IS NOT NULL THEN
        NEW.answer = NEW.answer_date::TEXT;
    ELSIF NEW.answer_time IS NOT NULL THEN
        NEW.answer = NEW.answer_time::TEXT;
    ELSIF NEW.selected_options IS NOT NULL THEN
        NEW.answer = NEW.selected_options::TEXT;
    END IF;
    
    -- When main answer column is updated, update appropriate type-specific column
    IF NEW.answer IS NOT NULL AND NEW.answer != '' AND NEW.question_id IS NOT NULL THEN
        -- Get question type from related question
        SELECT question_type INTO q_type 
        FROM job_category_questions 
        WHERE id = NEW.question_id;
        
        CASE q_type
            WHEN 'text' THEN
                IF NEW.answer_text IS NULL THEN
                    NEW.answer_text = NEW.answer;
                END IF;
            WHEN 'number' THEN
                IF NEW.answer_number IS NULL THEN
                    BEGIN
                        NEW.answer_number = NEW.answer::DECIMAL(10,2);
                    EXCEPTION WHEN OTHERS THEN
                        -- If conversion fails, store as text
                        NEW.answer_text = NEW.answer;
                    END;
                END IF;
            WHEN 'yes_no' THEN
                IF NEW.answer_boolean IS NULL THEN
                    NEW.answer_boolean = (NEW.answer ILIKE 'yes' OR NEW.answer ILIKE 'true');
                END IF;
            WHEN 'date' THEN
                IF NEW.answer_date IS NULL THEN
                    BEGIN
                        NEW.answer_date = NEW.answer::DATE;
                    EXCEPTION WHEN OTHERS THEN
                        -- If conversion fails, store as text
                        NEW.answer_text = NEW.answer;
                    END;
                END IF;
            WHEN 'time' THEN
                IF NEW.answer_time IS NULL THEN
                    BEGIN
                        NEW.answer_time = NEW.answer::TIME;
                    EXCEPTION WHEN OTHERS THEN
                        -- If conversion fails, store as text
                        NEW.answer_text = NEW.answer;
                    END;
                END IF;
            ELSE
                IF NEW.answer_text IS NULL THEN
                    NEW.answer_text = NEW.answer;
                END IF;
        END CASE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for answer synchronization
DROP TRIGGER IF EXISTS sync_job_question_answers_trigger ON job_question_answers;
CREATE TRIGGER sync_job_question_answers_trigger
    BEFORE INSERT OR UPDATE ON job_question_answers
    FOR EACH ROW EXECUTE FUNCTION sync_job_question_answers();

-- Create safer version of update_updated_at_column function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    -- Simple approach: just try to update updated_at and handle errors gracefully
    BEGIN
        NEW.updated_at = NOW();
    EXCEPTION WHEN undefined_column THEN
        -- Column does not exist, continue without error
        NULL;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 3: Ensure Job Categories Have Hourly Rate Structure
-- ============================================================================

-- Add hourly rate column to job_categories if it does not exist
ALTER TABLE job_categories ADD COLUMN IF NOT EXISTS default_hourly_rate DECIMAL(10,2) DEFAULT 2000.00;

-- Update existing categories with default hourly rates if they do not have them
UPDATE job_categories 
SET default_hourly_rate = CASE 
    WHEN name = 'House Cleaning' THEN 2500.00
    WHEN name = 'Deep Cleaning' THEN 3000.00
    WHEN name = 'Gardening' THEN 2000.00
    WHEN name = 'Cooking' THEN 2200.00
    WHEN name = 'Elderly Care' THEN 2800.00
    WHEN name = 'Child Care' THEN 2400.00
    WHEN name = 'Pet Care' THEN 1800.00
    WHEN name = 'Tutoring' THEN 3500.00
    WHEN name = 'Tech Support' THEN 4000.00
    WHEN name = 'Moving Help' THEN 2800.00
    WHEN name = 'Plumbing' THEN 3500.00
    WHEN name = 'Electrical Work' THEN 4000.00
    WHEN name = 'Painting' THEN 2500.00
    WHEN name = 'Furniture Assembly' THEN 2000.00
    WHEN name = 'Car Washing' THEN 1500.00
    WHEN name = 'Delivery Services' THEN 1800.00
    WHEN name = 'Event Planning' THEN 3000.00
    WHEN name = 'Shopping Assistance' THEN 2000.00
    WHEN name = 'Office Maintenance' THEN 2200.00
    WHEN name = 'Babysitting' THEN 2400.00
    WHEN name = 'Window Cleaning' THEN 2000.00
    WHEN name = 'Carpet Cleaning' THEN 2800.00
    WHEN name = 'Appliance Repair' THEN 4000.00
    WHEN name = 'Massage Therapy' THEN 3500.00
    WHEN name = 'Language Translation' THEN 3000.00
    WHEN name = 'Music Lessons' THEN 3500.00
    WHEN name = 'Art and Craft' THEN 2500.00
    WHEN name = 'Data Entry' THEN 2000.00
    WHEN name = 'Photography' THEN 4000.00
    WHEN name = 'Fitness Training' THEN 3000.00
    ELSE 2000.00
END
WHERE default_hourly_rate IS NULL;

-- ============================================================================
-- STEP 4: Create Function to Validate Required Questions
-- ============================================================================

-- Function to check if all required questions for a job are answered
CREATE OR REPLACE FUNCTION validate_job_required_questions(job_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    job_category_id UUID;
    required_questions_count INTEGER;
    answered_questions_count INTEGER;
BEGIN
    -- Get job category
    SELECT category_id INTO job_category_id 
    FROM jobs 
    WHERE id = job_id;
    
    IF job_category_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Count required questions for this category
    SELECT COUNT(*) INTO required_questions_count
    FROM job_category_questions 
    WHERE category_id = job_category_id 
    AND is_required = TRUE;
    
    -- Count answered required questions
    SELECT COUNT(*) INTO answered_questions_count
    FROM job_question_answers jqa
    JOIN job_category_questions jcq ON jqa.question_id = jcq.id
    WHERE jqa.job_id = job_id 
    AND jcq.is_required = TRUE
    AND (jqa.answer IS NOT NULL AND jqa.answer != '');
    
    RETURN answered_questions_count >= required_questions_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 5: Update Existing Data to Ensure Consistency
-- ============================================================================

-- Sync existing answers to main answer column
UPDATE job_question_answers 
SET answer = COALESCE(answer_text, answer_number::TEXT, 
                     CASE WHEN answer_boolean THEN 'Yes' ELSE 'No' END,
                     answer_date::TEXT, answer_time::TEXT, 
                     selected_options::TEXT)
WHERE answer IS NULL AND (
    answer_text IS NOT NULL OR 
    answer_number IS NOT NULL OR 
    answer_boolean IS NOT NULL OR 
    answer_date IS NOT NULL OR 
    answer_time IS NOT NULL OR 
    selected_options IS NOT NULL
);

-- Sync main answer column to type-specific columns where missing
UPDATE job_question_answers jqa
SET answer_text = jqa.answer
FROM job_category_questions jcq
WHERE jqa.question_id = jcq.id
AND jcq.question_type = 'text'
AND jqa.answer IS NOT NULL
AND jqa.answer_text IS NULL;

-- ============================================================================
-- STEP 6: Add Indexes for Performance
-- ============================================================================

-- Add indexes for job question answer lookups
CREATE INDEX IF NOT EXISTS idx_job_question_answers_job_question ON job_question_answers(job_id, question_id);
CREATE INDEX IF NOT EXISTS idx_job_question_answers_answer ON job_question_answers(answer);
CREATE INDEX IF NOT EXISTS idx_job_categories_hourly_rate ON job_categories(default_hourly_rate);
CREATE INDEX IF NOT EXISTS idx_job_question_answers_updated_at ON job_question_answers(updated_at);

-- Add updated_at trigger for job_question_answers if it does not exist
-- Note: sync_job_question_answers_trigger already handles updated_at
-- But add a backup trigger in case the sync trigger is removed
DROP TRIGGER IF EXISTS update_job_question_answers_updated_at ON job_question_answers;
CREATE TRIGGER update_job_question_answers_updated_at
    BEFORE UPDATE ON job_question_answers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- STEP 7: Create View for Job Categories with Hourly Rates
-- ============================================================================

-- Create view for easy access to job categories with hourly rates
CREATE OR REPLACE VIEW job_categories_with_rates AS
SELECT 
    id,
    name,
    description,
    default_hourly_rate,
    icon_name,
    is_active,
    created_at,
    CASE 
        WHEN default_hourly_rate IS NULL THEN 'No rate set'
        ELSE 'LKR ' || default_hourly_rate || '/hr'
    END as formatted_hourly_rate
FROM job_categories
WHERE is_active = TRUE
ORDER BY name;

-- ============================================================================
-- STEP 8: Verification Queries
-- ============================================================================

-- Verify the migration
DO $$ 
BEGIN
    -- Check if answer column exists in job_question_answers
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_question_answers' 
        AND column_name = 'answer'
    ) THEN
        RAISE NOTICE 'Answer column exists in job_question_answers table';
    ELSE
        RAISE EXCEPTION 'Answer column missing from job_question_answers table';
    END IF;
    
    -- Check if updated_at column exists in job_question_answers
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_question_answers' 
        AND column_name = 'updated_at'
    ) THEN
        RAISE NOTICE 'Updated_at column exists in job_question_answers table';
    ELSE
        RAISE EXCEPTION 'Updated_at column missing from job_question_answers table';
    END IF;
    
    -- Check if default_hourly_rate exists in job_categories
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_categories' 
        AND column_name = 'default_hourly_rate'
    ) THEN
        RAISE NOTICE 'Default hourly rate column exists in job_categories table';
    ELSE
        RAISE EXCEPTION 'Default hourly rate column missing from job_categories table';
    END IF;
    
    -- Check if validation function exists
    IF EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'validate_job_required_questions'
    ) THEN
        RAISE NOTICE 'Validation function created successfully';
    ELSE
        RAISE EXCEPTION 'Validation function not created';
    END IF;
    
    -- Check if sync function exists
    IF EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'sync_job_question_answers'
    ) THEN
        RAISE NOTICE 'Answer sync function created successfully';
    ELSE
        RAISE EXCEPTION 'Answer sync function not created';
    END IF;
END $$;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Summary of changes:
-- 1. Fixed job_question_answers table structure with answer field syncing
-- 2. Added updated_at column to job_question_answers table
-- 3. Added automatic trigger to sync answer fields with error handling
-- 4. Created safer update_updated_at_column function
-- 5. Ensured job_categories table has default_hourly_rate column
-- 6. Updated existing categories with appropriate hourly rates
-- 7. Created validation function for required questions
-- 8. Updated existing data for consistency
-- 9. Added performance indexes including updated_at
-- 10. Created view for job categories with formatted rates
-- 11. Added comprehensive verification checks

-- Next steps:
-- 1. Update Flutter app to use the fixed answer saving logic
-- 2. Add mandatory validation on frontend
-- 3. Test answer saving and fetching end-to-end 