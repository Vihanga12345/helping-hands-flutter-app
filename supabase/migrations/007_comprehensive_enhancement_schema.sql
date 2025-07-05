-- HELPING HANDS APP - COMPREHENSIVE ENHANCEMENT SCHEMA
-- ============================================================================
-- Migration 007: Payment System, Helper Job Types, Document Storage
-- Run this file in Supabase SQL Editor to add new functionality

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- STEP 1: Payment Methods & Cards Tables
-- ============================================================================

-- Payment methods table for user payment preferences
CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    method_type VARCHAR(20) NOT NULL CHECK (method_type IN ('cash', 'card')),
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User cards table for saved card details
CREATE TABLE IF NOT EXISTS user_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    card_holder_name VARCHAR(100) NOT NULL,
    card_number_last_four VARCHAR(4) NOT NULL, -- Store only last 4 digits for security
    card_number_encrypted TEXT, -- Encrypted full number (implement encryption in app)
    expiry_month INTEGER NOT NULL CHECK (expiry_month >= 1 AND expiry_month <= 12),
    expiry_year INTEGER NOT NULL CHECK (expiry_year >= 2024),
    card_type VARCHAR(20) DEFAULT 'Unknown', -- Visa, MasterCard, etc.
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- STEP 2: Helper Job Types & Capabilities
-- ============================================================================

-- Helper job types table to track what job categories a helper can do
CREATE TABLE IF NOT EXISTS helper_job_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    helper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_category_id UUID NOT NULL REFERENCES job_categories(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    hourly_rate DECIMAL(10,2) DEFAULT 2000.00, -- Helper's rate for this job type
    experience_level VARCHAR(20) DEFAULT 'beginner', -- beginner, intermediate, expert
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(helper_id, job_category_id) -- Prevent duplicate assignments
);

-- ============================================================================
-- STEP 3: Helper Documents & Certificates Storage
-- ============================================================================

-- Helper documents table for uploaded certificates, resumes, IDs, etc.
CREATE TABLE IF NOT EXISTS helper_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    helper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL, -- 'certificate', 'resume', 'id', 'portfolio', 'insurance'
    document_name VARCHAR(200) NOT NULL,
    document_url TEXT, -- URL to uploaded file (Supabase Storage or external)
    file_size_bytes BIGINT DEFAULT 0,
    file_type VARCHAR(50), -- PDF, JPG, PNG, etc.
    job_category_id UUID REFERENCES job_categories(id), -- NULL for general docs like ID/resume
    verification_status VARCHAR(20) DEFAULT 'pending', -- pending, verified, rejected
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- STEP 4: Job Questions & Answers Enhancement
-- ============================================================================

-- Ensure job_question_answers table exists for storing helpee answers
CREATE TABLE IF NOT EXISTS job_question_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES job_category_questions(id),
    answer_text TEXT,
    answer_number DECIMAL(10,2),
    answer_date DATE,
    answer_time TIME,
    answer_boolean BOOLEAN,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- STEP 5: Helper Earnings & Statistics Enhancement
-- ============================================================================

-- Helper earnings table for tracking payments and earnings
CREATE TABLE IF NOT EXISTS helper_earnings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    helper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_id UUID NOT NULL REFERENCES jobs(id),
    amount_earned DECIMAL(10,2) NOT NULL,
    hours_worked DECIMAL(5,2) DEFAULT 0,
    platform_fee DECIMAL(10,2) DEFAULT 0,
    net_earnings DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'pending', -- pending, paid, failed
    payment_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- STEP 6: Indexes for Performance
-- ============================================================================

-- Payment method indexes
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_default ON payment_methods(user_id, is_default);

-- User cards indexes
CREATE INDEX IF NOT EXISTS idx_user_cards_user_id ON user_cards(user_id);
CREATE INDEX IF NOT EXISTS idx_user_cards_default ON user_cards(user_id, is_default);
CREATE INDEX IF NOT EXISTS idx_user_cards_active ON user_cards(user_id, is_active);

-- Helper job types indexes
CREATE INDEX IF NOT EXISTS idx_helper_job_types_helper_id ON helper_job_types(helper_id);
CREATE INDEX IF NOT EXISTS idx_helper_job_types_category ON helper_job_types(job_category_id);
CREATE INDEX IF NOT EXISTS idx_helper_job_types_active ON helper_job_types(helper_id, is_active);

-- Helper documents indexes
CREATE INDEX IF NOT EXISTS idx_helper_documents_helper_id ON helper_documents(helper_id);
CREATE INDEX IF NOT EXISTS idx_helper_documents_type ON helper_documents(helper_id, document_type);
CREATE INDEX IF NOT EXISTS idx_helper_documents_category ON helper_documents(job_category_id);

-- Job question answers indexes
CREATE INDEX IF NOT EXISTS idx_job_question_answers_job_id ON job_question_answers(job_id);
CREATE INDEX IF NOT EXISTS idx_job_question_answers_question_id ON job_question_answers(question_id);

-- Helper earnings indexes
CREATE INDEX IF NOT EXISTS idx_helper_earnings_helper_id ON helper_earnings(helper_id);
CREATE INDEX IF NOT EXISTS idx_helper_earnings_job_id ON helper_earnings(job_id);
CREATE INDEX IF NOT EXISTS idx_helper_earnings_date ON helper_earnings(created_at);

-- ============================================================================
-- STEP 7: Updated Statistics Views
-- ============================================================================

-- Update helper_statistics view to include earnings data
DROP VIEW IF EXISTS helper_statistics;
CREATE OR REPLACE VIEW helper_statistics AS
SELECT 
    u.id as helper_id,
    u.first_name,
    u.last_name,
    COALESCE(u.display_name, u.first_name || ' ' || u.last_name) as display_name,
    u.created_at as member_since,
    COUNT(j.id) as total_jobs,
    COUNT(CASE WHEN j.status = 'pending' THEN 1 END) as pending_jobs,
    COUNT(CASE WHEN j.status = 'accepted' THEN 1 END) as accepted_jobs,
    COUNT(CASE WHEN j.status IN ('started', 'in_progress') THEN 1 END) as ongoing_jobs,
    COUNT(CASE WHEN j.status = 'completed' THEN 1 END) as completed_jobs,
    COUNT(CASE WHEN j.status = 'cancelled' THEN 1 END) as cancelled_jobs,
    COALESCE(AVG(CASE WHEN j.helpee_rating IS NOT NULL THEN j.helpee_rating END), 0) as average_rating_received,
    COALESCE(SUM(CASE WHEN j.total_amount IS NOT NULL THEN j.total_amount END), 0) as total_earned,
    COALESCE(SUM(he.net_earnings), 0) as total_net_earnings,
    COUNT(DISTINCT hjt.job_category_id) as job_types_count
FROM users u
LEFT JOIN jobs j ON u.id = j.assigned_helper_id
LEFT JOIN helper_earnings he ON u.id = he.helper_id
LEFT JOIN helper_job_types hjt ON u.id = hjt.helper_id AND hjt.is_active = true
WHERE u.user_type = 'helper'
GROUP BY u.id, u.first_name, u.last_name, u.display_name, u.created_at;

-- ============================================================================
-- STEP 8: Triggers for Data Consistency
-- ============================================================================

-- Function to ensure only one default payment method per user
CREATE OR REPLACE FUNCTION ensure_single_default_payment_method()
RETURNS TRIGGER AS $$
BEGIN
    -- If setting this as default, unset all others for this user
    IF NEW.is_default = true THEN
        UPDATE payment_methods 
        SET is_default = false 
        WHERE user_id = NEW.user_id AND id != NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for payment methods
DROP TRIGGER IF EXISTS trigger_single_default_payment_method ON payment_methods;
CREATE TRIGGER trigger_single_default_payment_method
    BEFORE INSERT OR UPDATE ON payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_default_payment_method();

-- Function to ensure only one default card per user
CREATE OR REPLACE FUNCTION ensure_single_default_card()
RETURNS TRIGGER AS $$
BEGIN
    -- If setting this as default, unset all others for this user
    IF NEW.is_default = true THEN
        UPDATE user_cards 
        SET is_default = false 
        WHERE user_id = NEW.user_id AND id != NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for user cards
DROP TRIGGER IF EXISTS trigger_single_default_card ON user_cards;
CREATE TRIGGER trigger_single_default_card
    BEFORE INSERT OR UPDATE ON user_cards
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_default_card();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers to new tables
DROP TRIGGER IF EXISTS update_payment_methods_updated_at ON payment_methods;
CREATE TRIGGER update_payment_methods_updated_at
    BEFORE UPDATE ON payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_cards_updated_at ON user_cards;
CREATE TRIGGER update_user_cards_updated_at
    BEFORE UPDATE ON user_cards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_helper_job_types_updated_at ON helper_job_types;
CREATE TRIGGER update_helper_job_types_updated_at
    BEFORE UPDATE ON helper_job_types
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_helper_documents_updated_at ON helper_documents;
CREATE TRIGGER update_helper_documents_updated_at
    BEFORE UPDATE ON helper_documents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- STEP 9: Sample Data for Testing (Optional)
-- ============================================================================

-- Insert default payment method for existing users (optional)
-- INSERT INTO payment_methods (user_id, method_type, is_default)
-- SELECT id, 'cash', true 
-- FROM users 
-- WHERE user_type = 'helpee'
-- ON CONFLICT DO NOTHING;

-- ============================================================================
-- STEP 10: Verification Queries
-- ============================================================================

-- Check if all tables were created successfully
SELECT 'Tables created successfully' as status,
       (SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN (
           'payment_methods', 'user_cards', 'helper_job_types', 
           'helper_documents', 'job_question_answers', 'helper_earnings'
       )) as tables_count;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- All new tables and functionality have been added
-- Next steps:
-- 1. Update Flutter app services to use new tables
-- 2. Implement payment functionality
-- 3. Add helper registration document upload
-- 4. Enhance helper profile with job types and documents 