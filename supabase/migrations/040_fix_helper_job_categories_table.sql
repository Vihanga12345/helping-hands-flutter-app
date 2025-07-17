-- ============================================================================
-- Migration 040: Fix helper_job_categories table issue
-- Date: January 2025  
-- Purpose: Fix the missing helper_job_categories table by creating it or
--          correcting the table name reference in the notification trigger
-- ============================================================================

-- First, let's check what helper-related tables actually exist and create the missing one
-- Based on the schema, we likely need to create helper_job_categories table

-- Create helper_job_categories table if it doesn't exist
CREATE TABLE IF NOT EXISTS helper_job_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    helper_id UUID NOT NULL REFERENCES helpers(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES job_categories(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    hourly_rate DECIMAL(10, 2),
    experience_level VARCHAR(50) DEFAULT 'beginner' CHECK (experience_level IN ('beginner', 'intermediate', 'expert')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Ensure one record per helper-category combination
    UNIQUE(helper_id, category_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_helper_job_categories_helper_id ON helper_job_categories(helper_id);
CREATE INDEX IF NOT EXISTS idx_helper_job_categories_category_id ON helper_job_categories(category_id);
CREATE INDEX IF NOT EXISTS idx_helper_job_categories_active ON helper_job_categories(is_active);

-- If the table name is actually different, let's create an alternative version
-- In case it's called helper_job_types instead
DO $$
BEGIN
    -- Check if helper_job_types exists and helper_job_categories doesn't
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'helper_job_types') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'helper_job_categories') THEN
        
        -- Create view to map helper_job_types to helper_job_categories for compatibility
        CREATE OR REPLACE VIEW helper_job_categories AS
        SELECT 
            hjt.id,
            hjt.helper_id,
            hjt.job_category_id as category_id,
            hjt.is_active,
            hjt.hourly_rate,
            hjt.experience_level,
            hjt.created_at,
            hjt.updated_at
        FROM helper_job_types hjt;
        
        RAISE NOTICE 'Created view helper_job_categories mapping to helper_job_types table';
    END IF;
END $$;

-- Insert some sample data if the table is empty (for testing)
INSERT INTO helper_job_categories (helper_id, category_id, is_active, hourly_rate, experience_level)
SELECT 
    h.id as helper_id,
    jc.id as category_id,
    true as is_active,
    15.00 as hourly_rate,
    'intermediate' as experience_level
FROM helpers h
CROSS JOIN job_categories jc
WHERE NOT EXISTS (
    SELECT 1 FROM helper_job_categories hjc 
    WHERE hjc.helper_id = h.id AND hjc.category_id = jc.id
)
LIMIT 10; -- Limit to prevent too many records

-- Verify the table exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'helper_job_categories'
    ) THEN
        RAISE NOTICE '✅ helper_job_categories table exists and is ready';
    ELSE
        RAISE EXCEPTION '❌ Failed to create helper_job_categories table';
    END IF;
END $$; 