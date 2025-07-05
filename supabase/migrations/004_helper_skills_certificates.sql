-- Migration: Add Helper Skills and Certificates Tables
-- Date: December 2024
-- Purpose: Support enhanced helper registration with job types and certificates

-- Helper Skills Table
CREATE TABLE helper_skills (
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

-- Helper Certificates Table
CREATE TABLE helper_certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    helper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill_category VARCHAR(100) NOT NULL,
    certificate_name VARCHAR(200) NOT NULL,
    certificate_url VARCHAR(500),
    certificate_type VARCHAR(50) DEFAULT 'image', -- 'image', 'pdf', 'document'
    file_size BIGINT,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(id),
    
    -- Constraints
    CONSTRAINT helper_certificates_size_check CHECK (file_size > 0)
);

-- Helper Documents Table (ID photos and other documents)
CREATE TABLE helper_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    helper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL, -- 'id_front', 'id_back', 'profile_photo', 'police_clearance'
    document_name VARCHAR(200) NOT NULL,
    document_url VARCHAR(500),
    file_type VARCHAR(20) DEFAULT 'image', -- 'image', 'pdf'
    file_size BIGINT,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(id),
    
    -- Constraints
    CONSTRAINT helper_documents_size_check CHECK (file_size > 0),
    UNIQUE(helper_id, document_type)
);

-- Helper Profile Enhancement
ALTER TABLE users ADD COLUMN IF NOT EXISTS hourly_rate_default DECIMAL(10,2) DEFAULT 2000.00;
ALTER TABLE users ADD COLUMN IF NOT EXISTS availability_status VARCHAR(20) DEFAULT 'available'; -- 'available', 'busy', 'offline'
ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_status VARCHAR(20) DEFAULT 'pending'; -- 'pending', 'verified', 'rejected'
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_completion_percentage INTEGER DEFAULT 30;

-- Create indexes for performance
CREATE INDEX idx_helper_skills_helper_id ON helper_skills(helper_id);
CREATE INDEX idx_helper_skills_category ON helper_skills(skill_category);
CREATE INDEX idx_helper_skills_active ON helper_skills(is_active);

CREATE INDEX idx_helper_certificates_helper_id ON helper_certificates(helper_id);
CREATE INDEX idx_helper_certificates_category ON helper_certificates(skill_category);
CREATE INDEX idx_helper_certificates_verified ON helper_certificates(is_verified);

CREATE INDEX idx_helper_documents_helper_id ON helper_documents(helper_id);
CREATE INDEX idx_helper_documents_type ON helper_documents(document_type);
CREATE INDEX idx_helper_documents_verified ON helper_documents(is_verified);

-- Create views for easier querying
CREATE OR REPLACE VIEW helper_profile_complete AS
SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.phone,
    u.location_city,
    u.hourly_rate_default,
    u.availability_status,
    u.verification_status,
    u.profile_completion_percentage,
    COUNT(DISTINCT hs.id) as total_skills,
    COUNT(DISTINCT hc.id) as total_certificates,
    COUNT(DISTINCT hd.id) as total_documents,
    AVG(hs.hourly_rate) as average_hourly_rate,
    ARRAY_AGG(DISTINCT hs.skill_category) FILTER (WHERE hs.skill_category IS NOT NULL) as skills,
    CASE 
        WHEN COUNT(DISTINCT hd.id) FILTER (WHERE hd.document_type IN ('id_front', 'id_back')) = 2 
        THEN true 
        ELSE false 
    END as has_required_documents
FROM users u
LEFT JOIN helper_skills hs ON u.id = hs.helper_id AND hs.is_active = true
LEFT JOIN helper_certificates hc ON u.id = hc.helper_id
LEFT JOIN helper_documents hd ON u.id = hd.helper_id
WHERE u.user_type = 'helper'
GROUP BY u.id, u.first_name, u.last_name, u.email, u.phone, u.location_city, 
         u.hourly_rate_default, u.availability_status, u.verification_status, u.profile_completion_percentage;

-- Insert sample job categories that match the registration page
INSERT INTO job_categories (name, description, base_hourly_rate) VALUES
('House Cleaning', 'General house cleaning services', 2500.00),
('Deep Cleaning', 'Thorough deep cleaning services', 3000.00),
('Gardening', 'Garden maintenance and landscaping', 2000.00),
('Cooking', 'Meal preparation and cooking', 2500.00),
('Elderly Care', 'Care for elderly individuals', 2800.00),
('Childcare', 'Looking after children', 2200.00),
('Pet Care', 'Pet sitting and care', 1800.00),
('Tutoring', 'Educational tutoring services', 3500.00)
ON CONFLICT (name) DO UPDATE SET 
    description = EXCLUDED.description,
    base_hourly_rate = EXCLUDED.base_hourly_rate;

-- Function to calculate profile completion percentage
CREATE OR REPLACE FUNCTION calculate_helper_profile_completion(helper_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    completion_percentage INTEGER := 0;
    skill_count INTEGER;
    document_count INTEGER;
    required_doc_count INTEGER;
BEGIN
    -- Basic profile info (30% - already exists from registration)
    completion_percentage := 30;
    
    -- Skills added (30%)
    SELECT COUNT(*) INTO skill_count FROM helper_skills WHERE helper_id = helper_user_id AND is_active = true;
    IF skill_count >= 2 THEN
        completion_percentage := completion_percentage + 30;
    END IF;
    
    -- Required documents uploaded (30%)
    SELECT COUNT(*) INTO required_doc_count 
    FROM helper_documents 
    WHERE helper_id = helper_user_id AND document_type IN ('id_front', 'id_back');
    
    IF required_doc_count = 2 THEN
        completion_percentage := completion_percentage + 30;
    END IF;
    
    -- Additional documents/certificates (10%)
    SELECT COUNT(*) INTO document_count 
    FROM helper_certificates 
    WHERE helper_id = helper_user_id;
    
    IF document_count > 0 THEN
        completion_percentage := completion_percentage + 10;
    END IF;
    
    RETURN completion_percentage;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update profile completion when skills/documents change
CREATE OR REPLACE FUNCTION update_helper_profile_completion()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users 
    SET profile_completion_percentage = calculate_helper_profile_completion(
        CASE 
            WHEN TG_OP = 'DELETE' THEN OLD.helper_id
            ELSE NEW.helper_id
        END
    )
    WHERE id = CASE 
        WHEN TG_OP = 'DELETE' THEN OLD.helper_id
        ELSE NEW.helper_id
    END;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_helper_skills_completion ON helper_skills;
CREATE TRIGGER trigger_helper_skills_completion
    AFTER INSERT OR UPDATE OR DELETE ON helper_skills
    FOR EACH ROW EXECUTE FUNCTION update_helper_profile_completion();

DROP TRIGGER IF EXISTS trigger_helper_documents_completion ON helper_documents;
CREATE TRIGGER trigger_helper_documents_completion
    AFTER INSERT OR UPDATE OR DELETE ON helper_documents
    FOR EACH ROW EXECUTE FUNCTION update_helper_profile_completion();

DROP TRIGGER IF EXISTS trigger_helper_certificates_completion ON helper_certificates;
CREATE TRIGGER trigger_helper_certificates_completion
    AFTER INSERT OR UPDATE OR DELETE ON helper_certificates
    FOR EACH ROW EXECUTE FUNCTION update_helper_profile_completion();

-- Grant appropriate permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON helper_skills TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON helper_certificates TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON helper_documents TO authenticated;
GRANT SELECT ON helper_profile_complete TO authenticated; 