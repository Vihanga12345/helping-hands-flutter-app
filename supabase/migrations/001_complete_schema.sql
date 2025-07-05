-- HELPING HANDS APP - COMPLETE DATABASE SCHEMA
-- ============================================================================
-- This file creates all the required tables for the Helping Hands application
-- Run this in your Supabase SQL Editor to set up the complete database

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- USER AUTHENTICATION AND PROFILES
-- ============================================================================

-- Custom authentication table (separate from Supabase Auth)
CREATE TABLE IF NOT EXISTS user_authentication (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('helpee', 'helper', 'admin')),
    user_id UUID NOT NULL, -- Links to users table
    is_active BOOLEAN DEFAULT true,
    login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMP,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User profiles table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    display_name VARCHAR(200),
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(20),
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('helpee', 'helper', 'admin')),
    profile_image_url TEXT,
    about_me TEXT,
    location_address TEXT,
    location_city VARCHAR(100),
    location_district VARCHAR(100),
    location_latitude DECIMAL(10, 8),
    location_longitude DECIMAL(11, 8),
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User sessions table for session management
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_auth_id UUID NOT NULL REFERENCES user_authentication(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    device_info TEXT,
    ip_address INET,
    expires_at TIMESTAMP NOT NULL,
    last_activity TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- JOB CATEGORIES AND QUESTIONS
-- ============================================================================

-- Job categories table
CREATE TABLE IF NOT EXISTS job_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon_name VARCHAR(100),
    default_hourly_rate DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Job category questions for dynamic forms
CREATE TABLE IF NOT EXISTS job_category_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES job_categories(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    question_type VARCHAR(50) NOT NULL CHECK (question_type IN ('text', 'number', 'yes_no', 'multiple_choice', 'checkbox', 'date', 'time')),
    options JSONB, -- For multiple choice and checkbox questions
    placeholder_text TEXT,
    is_required BOOLEAN DEFAULT true,
    order_index INTEGER DEFAULT 0,
    validation_rules JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- JOBS AND APPLICATIONS
-- ============================================================================

-- Jobs table (job requests from helpees)
CREATE TABLE IF NOT EXISTS jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    helpee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_helper_id UUID REFERENCES users(id) ON DELETE SET NULL,
    category_id UUID NOT NULL REFERENCES job_categories(id),
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    job_type VARCHAR(20) NOT NULL CHECK (job_type IN ('public', 'private')),
    invited_helper_email VARCHAR(255), -- For private jobs
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'in_progress', 'paused', 'completed', 'cancelled', 'rejected')),
    hourly_rate DECIMAL(10, 2) NOT NULL,
    estimated_hours DECIMAL(5, 2),
    actual_hours DECIMAL(5, 2),
    total_amount DECIMAL(10, 2),
    scheduled_date DATE NOT NULL,
    scheduled_start_time TIME NOT NULL,
    scheduled_end_time TIME,
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,
    location_type VARCHAR(50) DEFAULT 'on_site',
    location_address TEXT NOT NULL,
    location_city VARCHAR(100),
    location_district VARCHAR(100),
    location_latitude DECIMAL(10, 8),
    location_longitude DECIMAL(11, 8),
    special_instructions TEXT,
    payment_method VARCHAR(50) DEFAULT 'cash' CHECK (payment_method IN ('cash', 'card', 'bank_transfer', 'digital_wallet')),
    payment_status VARCHAR(50) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded', 'disputed')),
    requires_own_supplies BOOLEAN DEFAULT false,
    pet_friendly_required BOOLEAN DEFAULT false,
    urgency_level VARCHAR(20) DEFAULT 'normal' CHECK (urgency_level IN ('low', 'normal', 'high', 'urgent')),
    completion_notes TEXT,
    helpee_rating INTEGER CHECK (helpee_rating >= 1 AND helpee_rating <= 5),
    helper_rating INTEGER CHECK (helper_rating >= 1 AND helper_rating <= 5),
    helpee_review TEXT,
    helper_review TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Job question answers (responses to category-specific questions)
CREATE TABLE IF NOT EXISTS job_question_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES job_category_questions(id) ON DELETE CASCADE,
    answer TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(job_id, question_id)
);

-- ============================================================================
-- STORED PROCEDURES FOR APP FUNCTIONALITY
-- ============================================================================

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
    -- Create user profile first
    INSERT INTO users (
        email, username, first_name, last_name, phone, user_type, 
        display_name, location_city
    ) VALUES (
        p_email, p_username, p_first_name, p_last_name, p_phone, p_user_type,
        p_first_name || ' ' || p_last_name, 'Colombo'
    ) RETURNING id INTO new_user_id;
    
    -- Create authentication record
    INSERT INTO user_authentication (
        username, email, password_hash, user_type, user_id
    ) VALUES (
        p_username, p_email, p_password_hash, p_user_type, new_user_id
    ) RETURNING id INTO new_auth_id;
    
    RETURN new_user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to create job with helpee details
CREATE OR REPLACE FUNCTION create_job_with_helpee_details(
    p_helpee_id UUID,
    p_category_id UUID,
    p_title VARCHAR(200),
    p_description TEXT,
    p_job_type VARCHAR(20),
    p_hourly_rate DECIMAL(10, 2),
    p_scheduled_date DATE,
    p_scheduled_start_time TIME,
    p_location_latitude DECIMAL(10, 8),
    p_location_longitude DECIMAL(11, 8),
    p_location_address TEXT
) RETURNS UUID AS $$
DECLARE
    new_job_id UUID;
BEGIN
    INSERT INTO jobs (
        helpee_id, category_id, title, description, job_type,
        hourly_rate, scheduled_date, scheduled_start_time,
        location_latitude, location_longitude, location_address
    ) VALUES (
        p_helpee_id, p_category_id, p_title, p_description, p_job_type,
        p_hourly_rate, p_scheduled_date, p_scheduled_start_time,
        p_location_latitude, p_location_longitude, p_location_address
    ) RETURNING id INTO new_job_id;
    
    RETURN new_job_id;
END;
$$ LANGUAGE plpgsql;

-- Function to assign helper to job
CREATE OR REPLACE FUNCTION assign_helper_to_job(
    p_job_id UUID,
    p_helper_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE jobs 
    SET assigned_helper_id = p_helper_id, 
        status = 'accepted',
        updated_at = NOW()
    WHERE id = p_job_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Authentication indexes
CREATE INDEX IF NOT EXISTS idx_user_authentication_email ON user_authentication(email);
CREATE INDEX IF NOT EXISTS idx_user_authentication_username ON user_authentication(username);
CREATE INDEX IF NOT EXISTS idx_user_authentication_user_type ON user_authentication(user_type);

-- User indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_user_type ON users(user_type);

-- Job indexes
CREATE INDEX IF NOT EXISTS idx_jobs_helpee_id ON jobs(helpee_id);
CREATE INDEX IF NOT EXISTS idx_jobs_helper_id ON jobs(assigned_helper_id);
CREATE INDEX IF NOT EXISTS idx_jobs_category_id ON jobs(category_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_job_type ON jobs(job_type);

-- Session indexes
CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_auth_id ON user_sessions(user_auth_id);

-- ============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to relevant tables (drop if exists first)
DROP TRIGGER IF EXISTS update_user_authentication_updated_at ON user_authentication;
CREATE TRIGGER update_user_authentication_updated_at BEFORE UPDATE ON user_authentication FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_job_categories_updated_at ON job_categories;
CREATE TRIGGER update_job_categories_updated_at BEFORE UPDATE ON job_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_job_category_questions_updated_at ON job_category_questions;
CREATE TRIGGER update_job_category_questions_updated_at BEFORE UPDATE ON job_category_questions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_jobs_updated_at ON jobs;
CREATE TRIGGER update_jobs_updated_at BEFORE UPDATE ON jobs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
