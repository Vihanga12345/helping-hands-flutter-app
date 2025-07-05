-- Helping Hands App - Authentication System & Job Questions Enhancement
-- Migration: 003_authentication_and_job_questions.sql

-- 1. CUSTOM AUTHENTICATION TABLE
-- This replaces Supabase Auth for our dual user type system
CREATE TABLE user_authentication (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL, -- Unique username for each user
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- Encrypted password
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('helper', 'helpee')),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- Link to main user profile
    is_email_verified BOOLEAN DEFAULT FALSE,
    email_verification_token VARCHAR(255),
    password_reset_token VARCHAR(255),
    password_reset_expires TIMESTAMP WITH TIME ZONE,
    last_login TIMESTAMP WITH TIME ZONE,
    login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. JOB CATEGORY QUESTIONS TABLE
-- Predefined questions for each job category
CREATE TABLE job_category_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES job_categories(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type VARCHAR(20) NOT NULL CHECK (question_type IN ('text', 'multiple_choice', 'checkbox', 'number', 'date', 'time')),
    question_order INTEGER NOT NULL, -- Order of questions (1-5)
    is_required BOOLEAN DEFAULT TRUE,
    options JSONB, -- For multiple choice/checkbox questions
    placeholder_text VARCHAR(255),
    validation_rules JSONB, -- Min/max length, regex patterns, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(category_id, question_order) -- Ensure unique order per category
);

-- 3. JOB QUESTION ANSWERS TABLE
-- Stores answers to job-specific questions when helpee creates a job
CREATE TABLE job_question_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES job_category_questions(id) ON DELETE CASCADE,
    answer_text TEXT, -- For text/number answers
    selected_options JSONB, -- For multiple choice/checkbox answers
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(job_id, question_id) -- One answer per question per job
);

-- 4. USER SESSIONS TABLE
-- Track active user sessions for security
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_auth_id UUID NOT NULL REFERENCES user_authentication(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    device_info TEXT,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. ENHANCE USERS TABLE WITH USERNAME
-- Add username field to main users table for better identification
ALTER TABLE users ADD COLUMN username VARCHAR(50) UNIQUE;
ALTER TABLE users ADD COLUMN display_name VARCHAR(100); -- Full name for display

-- 6. ENHANCE JOBS TABLE WITH HELPEE DETAILS
-- Add helpee identification fields for better job tracking
ALTER TABLE jobs ADD COLUMN helpee_username VARCHAR(50);
ALTER TABLE jobs ADD COLUMN helpee_display_name VARCHAR(100);
ALTER TABLE jobs ADD COLUMN helper_username VARCHAR(50);
ALTER TABLE jobs ADD COLUMN helper_display_name VARCHAR(100);

-- INDEXES for better performance
CREATE INDEX idx_user_authentication_username ON user_authentication(username);
CREATE INDEX idx_user_authentication_email ON user_authentication(email);
CREATE INDEX idx_user_authentication_user_type ON user_authentication(user_type);
CREATE INDEX idx_user_authentication_user_id ON user_authentication(user_id);

CREATE INDEX idx_job_category_questions_category_id ON job_category_questions(category_id);
CREATE INDEX idx_job_category_questions_order ON job_category_questions(category_id, question_order);

CREATE INDEX idx_job_question_answers_job_id ON job_question_answers(job_id);
CREATE INDEX idx_job_question_answers_question_id ON job_question_answers(question_id);

CREATE INDEX idx_user_sessions_user_auth_id ON user_sessions(user_auth_id);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_user_sessions_expires ON user_sessions(expires_at);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_jobs_helpee_username ON jobs(helpee_username);
CREATE INDEX idx_jobs_helper_username ON jobs(helper_username);

-- TRIGGERS for updated_at timestamps
CREATE TRIGGER update_user_authentication_updated_at BEFORE UPDATE ON user_authentication
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_job_category_questions_updated_at BEFORE UPDATE ON job_category_questions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_job_question_answers_updated_at BEFORE UPDATE ON job_question_answers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- FUNCTIONS for authentication and job management

-- Function to create user with authentication
CREATE OR REPLACE FUNCTION create_user_with_auth(
    p_username VARCHAR(50),
    p_email VARCHAR(255),
    p_password_hash VARCHAR(255),
    p_user_type VARCHAR(20),
    p_first_name VARCHAR(100),
    p_last_name VARCHAR(100),
    p_phone VARCHAR(20)
) RETURNS UUID AS $$
DECLARE
    new_user_id UUID;
    new_auth_id UUID;
BEGIN
    -- Create user profile
    INSERT INTO users (email, phone, first_name, last_name, user_type, username, display_name)
    VALUES (p_email, p_phone, p_first_name, p_last_name, p_user_type, p_username, p_first_name || ' ' || p_last_name)
    RETURNING id INTO new_user_id;
    
    -- Create authentication record
    INSERT INTO user_authentication (username, email, password_hash, user_type, user_id)
    VALUES (p_username, p_email, p_password_hash, p_user_type, new_user_id)
    RETURNING id INTO new_auth_id;
    
    RETURN new_user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update job with helper assignment
CREATE OR REPLACE FUNCTION assign_helper_to_job(
    p_job_id UUID,
    p_helper_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    helper_username VARCHAR(50);
    helper_name VARCHAR(100);
BEGIN
    -- Get helper details
    SELECT username, display_name INTO helper_username, helper_name
    FROM users WHERE id = p_helper_id AND user_type = 'helper';
    
    IF helper_username IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Update job with helper details
    UPDATE jobs 
    SET assigned_helper_id = p_helper_id,
        helper_username = helper_username,
        helper_display_name = helper_name,
        status = 'accepted',
        updated_at = NOW()
    WHERE id = p_job_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to create job with helpee details
CREATE OR REPLACE FUNCTION create_job_with_helpee_details(
    p_helpee_id UUID,
    p_category_id UUID,
    p_title VARCHAR(200),
    p_description TEXT,
    p_job_type VARCHAR(20),
    p_hourly_rate DECIMAL(10,2),
    p_scheduled_date DATE,
    p_scheduled_start_time TIME,
    p_location_latitude DECIMAL(10,8),
    p_location_longitude DECIMAL(11,8),
    p_location_address TEXT
) RETURNS UUID AS $$
DECLARE
    new_job_id UUID;
    helpee_username VARCHAR(50);
    helpee_name VARCHAR(100);
BEGIN
    -- Get helpee details
    SELECT username, display_name INTO helpee_username, helpee_name
    FROM users WHERE id = p_helpee_id AND user_type = 'helpee';
    
    -- Create job with helpee details
    INSERT INTO jobs (
        helpee_id, category_id, title, description, job_type, hourly_rate,
        scheduled_date, scheduled_start_time, location_latitude, location_longitude,
        location_address, helpee_username, helpee_display_name
    ) VALUES (
        p_helpee_id, p_category_id, p_title, p_description, p_job_type, p_hourly_rate,
        p_scheduled_date, p_scheduled_start_time, p_location_latitude, p_location_longitude,
        p_location_address, helpee_username, helpee_name
    ) RETURNING id INTO new_job_id;
    
    RETURN new_job_id;
END;
$$ LANGUAGE plpgsql; 