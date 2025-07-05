-- Helper Skills and Certificates Enhancement
-- Date: December 2024

-- Helper Skills Table
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
    
    CONSTRAINT helper_skills_experience_check CHECK (experience_years >= 0),
    CONSTRAINT helper_skills_rate_check CHECK (hourly_rate >= 0),
    UNIQUE(helper_id, skill_category)
);

-- Helper Certificates Table
CREATE TABLE IF NOT EXISTS helper_certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    helper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill_category VARCHAR(100) NOT NULL,
    certificate_name VARCHAR(200) NOT NULL,
    certificate_url VARCHAR(500),
    certificate_type VARCHAR(50) DEFAULT 'image',
    file_size BIGINT,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(id)
);

-- Helper Documents Table
CREATE TABLE IF NOT EXISTS helper_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    helper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL,
    document_name VARCHAR(200) NOT NULL,
    document_url VARCHAR(500),
    file_type VARCHAR(20) DEFAULT 'image',
    file_size BIGINT,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(id),
    
    UNIQUE(helper_id, document_type)
);

-- Add columns to users table for helpers
ALTER TABLE users ADD COLUMN IF NOT EXISTS hourly_rate_default DECIMAL(10,2) DEFAULT 2000.00;
ALTER TABLE users ADD COLUMN IF NOT EXISTS availability_status VARCHAR(20) DEFAULT 'available';
ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_status VARCHAR(20) DEFAULT 'pending';
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_completion_percentage INTEGER DEFAULT 30;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_helper_skills_helper_id ON helper_skills(helper_id);
CREATE INDEX IF NOT EXISTS idx_helper_certificates_helper_id ON helper_certificates(helper_id);
CREATE INDEX IF NOT EXISTS idx_helper_documents_helper_id ON helper_documents(helper_id); 