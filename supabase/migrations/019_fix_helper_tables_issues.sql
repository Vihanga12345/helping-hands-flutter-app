-- Migration: Fix Helper Tables Issues
-- Purpose: Ensure helper_skills table exists and fix any missing data relationships

-- 1. Ensure helper_skills table exists with correct structure
CREATE TABLE IF NOT EXISTS helper_skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    helper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill_category VARCHAR(100) NOT NULL,
    skill_name VARCHAR(200) NOT NULL,
    experience_years INTEGER DEFAULT 0,
    hourly_rate DECIMAL(10,2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT helper_skills_experience_check CHECK (experience_years >= 0),
    CONSTRAINT helper_skills_rate_check CHECK (hourly_rate >= 0),
    UNIQUE(helper_id, skill_category)
);

-- 2. Ensure helper_job_types table exists with correct structure
CREATE TABLE IF NOT EXISTS helper_job_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    helper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_category_id UUID NOT NULL REFERENCES job_categories(id) ON DELETE CASCADE,
    hourly_rate DECIMAL(10,2),
    experience_level VARCHAR(50) DEFAULT 'beginner',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT helper_job_types_rate_check CHECK (hourly_rate >= 0),
    UNIQUE(helper_id, job_category_id)
);

-- 3. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_helper_skills_helper_id ON helper_skills(helper_id);
CREATE INDEX IF NOT EXISTS idx_helper_skills_category ON helper_skills(skill_category);
CREATE INDEX IF NOT EXISTS idx_helper_skills_active ON helper_skills(is_active);

CREATE INDEX IF NOT EXISTS idx_helper_job_types_helper_id ON helper_job_types(helper_id);
CREATE INDEX IF NOT EXISTS idx_helper_job_types_category ON helper_job_types(job_category_id);
CREATE INDEX IF NOT EXISTS idx_helper_job_types_active ON helper_job_types(helper_id, is_active);

-- 4. Populate helper_skills table with sample data if empty
DO $$
BEGIN
    -- Check if helper_skills table is empty and we have helpers
    IF NOT EXISTS (SELECT 1 FROM helper_skills LIMIT 1) 
       AND EXISTS (SELECT 1 FROM users WHERE user_type = 'helper' LIMIT 1) THEN
        
        -- Insert sample skills for existing helpers
        INSERT INTO helper_skills (helper_id, skill_category, skill_name, experience_years, hourly_rate, is_active)
        SELECT 
            u.id,
            'House Cleaning',
            'General House Cleaning',
            1,
            2500.00,
            true
        FROM users u 
        WHERE u.user_type = 'helper'
        ON CONFLICT (helper_id, skill_category) DO NOTHING;
        
        -- Add more sample skills
        INSERT INTO helper_skills (helper_id, skill_category, skill_name, experience_years, hourly_rate, is_active)
        SELECT 
            u.id,
            'Gardening',
            'Garden Maintenance',
            2,
            2000.00,
            true
        FROM users u 
        WHERE u.user_type = 'helper'
        LIMIT 3  -- Only for first 3 helpers
        ON CONFLICT (helper_id, skill_category) DO NOTHING;
        
        RAISE NOTICE 'Populated helper_skills table with sample data';
    END IF;
END $$;

-- 5. Create a function to get helper job categories from skills
CREATE OR REPLACE FUNCTION get_helper_job_categories(p_helper_id UUID)
RETURNS TABLE (
    category_name VARCHAR(100),
    hourly_rate DECIMAL(10,2),
    experience_years INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        hs.skill_category,
        hs.hourly_rate,
        hs.experience_years
    FROM helper_skills hs
    WHERE hs.helper_id = p_helper_id 
    AND hs.is_active = true
    ORDER BY hs.created_at;
END;
$$ LANGUAGE plpgsql;

-- 6. Grant appropriate permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON helper_skills TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON helper_job_types TO authenticated;
GRANT EXECUTE ON FUNCTION get_helper_job_categories(UUID) TO authenticated;

-- 7. Add updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_helper_skills_updated_at ON helper_skills;
CREATE TRIGGER update_helper_skills_updated_at
    BEFORE UPDATE ON helper_skills
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_helper_job_types_updated_at ON helper_job_types;
CREATE TRIGGER update_helper_job_types_updated_at
    BEFORE UPDATE ON helper_job_types
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- MIGRATION VERIFICATION
-- ============================================================================

DO $$
BEGIN
    -- Check if helper_skills table exists and has proper structure
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'helper_skills') THEN
        RAISE NOTICE '✅ helper_skills table exists';
        
        -- Check if there's data
        IF EXISTS (SELECT 1 FROM helper_skills LIMIT 1) THEN
            RAISE NOTICE '✅ helper_skills table has data';
        ELSE
            RAISE NOTICE 'ℹ️ helper_skills table is empty (will be populated as helpers register)';
        END IF;
    ELSE
        RAISE EXCEPTION '❌ helper_skills table missing';
    END IF;
    
    -- Check if helper_job_types table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'helper_job_types') THEN
        RAISE NOTICE '✅ helper_job_types table exists';
    ELSE
        RAISE EXCEPTION '❌ helper_job_types table missing';
    END IF;
    
    -- Check if function exists
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'get_helper_job_categories') THEN
        RAISE NOTICE '✅ get_helper_job_categories function exists';
    ELSE
        RAISE EXCEPTION '❌ get_helper_job_categories function missing';
    END IF;
    
    RAISE NOTICE '🎉 Migration 019_fix_helper_tables_issues completed successfully!';
END $$; 