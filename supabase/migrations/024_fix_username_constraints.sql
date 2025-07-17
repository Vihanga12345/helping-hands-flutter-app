-- HELPING HANDS APP - FIX USERNAME CONSTRAINTS
-- ============================================================================
-- Migration: 024_fix_username_constraints.sql
-- Purpose: Allow same usernames for different user types
-- Date: January 2025

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- STEP 1: Fix users table username constraint
-- ============================================================================

-- Drop existing unique constraint on username in users table
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_username_key;

-- Create composite unique constraint (username + user_type)
ALTER TABLE users ADD CONSTRAINT users_username_user_type_key UNIQUE (username, user_type);

-- ============================================================================
-- STEP 2: Fix user_authentication table username constraint
-- ============================================================================

-- Drop existing unique constraint on username in user_authentication table
ALTER TABLE user_authentication DROP CONSTRAINT IF EXISTS user_authentication_username_key;

-- Create composite unique constraint (username + user_type)
ALTER TABLE user_authentication ADD CONSTRAINT user_authentication_username_user_type_key UNIQUE (username, user_type);

-- ============================================================================
-- STEP 3: Update the create_user_with_auth function to handle new constraints
-- ============================================================================

-- Function to create user with authentication (updated for new constraints)
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
    -- Check if username already exists for this user type
    IF EXISTS (
        SELECT 1 FROM users 
        WHERE username = p_username AND user_type = p_user_type
    ) THEN
        RAISE EXCEPTION 'Username already exists for this user type';
    END IF;
    
    -- Check if email already exists (email should be unique across all user types)
    IF EXISTS (
        SELECT 1 FROM users 
        WHERE email = p_email
    ) THEN
        RAISE EXCEPTION 'Email already exists';
    END IF;
    
    -- Create user profile first
    INSERT INTO users (
        email, username, first_name, last_name, phone, user_type, 
        display_name, location_city, created_at, updated_at
    ) VALUES (
        p_email, p_username, p_first_name, p_last_name, p_phone, p_user_type,
        p_first_name || ' ' || p_last_name, 'Colombo', NOW(), NOW()
    ) RETURNING id INTO new_user_id;
    
    -- Create authentication record
    INSERT INTO user_authentication (
        username, email, password_hash, user_type, user_id, created_at, updated_at
    ) VALUES (
        p_username, p_email, p_password_hash, p_user_type, new_user_id, NOW(), NOW()
    ) RETURNING id INTO new_auth_id;
    
    RETURN new_user_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 4: Create function to check username availability for specific user type
-- ============================================================================

CREATE OR REPLACE FUNCTION check_username_availability(
    p_username VARCHAR(50),
    p_user_type VARCHAR(20)
) RETURNS BOOLEAN AS $$
BEGIN
    -- Return true if username is available for this user type
    RETURN NOT EXISTS (
        SELECT 1 FROM users 
        WHERE username = p_username AND user_type = p_user_type
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 5: Add indexes for better performance
-- ============================================================================

-- Create indexes for the new composite constraints
CREATE INDEX IF NOT EXISTS idx_users_username_user_type ON users(username, user_type);
CREATE INDEX IF NOT EXISTS idx_user_authentication_username_user_type ON user_authentication(username, user_type);

-- ============================================================================
-- STEP 6: Test data insertion (for validation)
-- ============================================================================

-- Insert test data to verify the fix works
DO $$
BEGIN
    -- Test: Same username for different user types should work
    BEGIN
        -- Create helpee with username 'testuser'
        INSERT INTO users (id, email, username, first_name, last_name, phone, user_type, display_name, location_city) 
        VALUES (gen_random_uuid(), 'testuser_helpee@test.com', 'testuser', 'Test', 'Helpee', '0771234567', 'helpee', 'Test Helpee', 'Colombo');
        
        -- Create helper with same username 'testuser' - should work
        INSERT INTO users (id, email, username, first_name, last_name, phone, user_type, display_name, location_city) 
        VALUES (gen_random_uuid(), 'testuser_helper@test.com', 'testuser', 'Test', 'Helper', '0771234568', 'helper', 'Test Helper', 'Colombo');
        
        RAISE NOTICE 'SUCCESS: Same username for different user types works correctly';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: Failed to create users with same username for different types: %', SQLERRM;
    END;
    
    -- Clean up test data
    DELETE FROM users WHERE username = 'testuser';
END $$;

-- ============================================================================
-- STEP 7: Add comments for documentation
-- ============================================================================

COMMENT ON CONSTRAINT users_username_user_type_key ON users IS 'Allows same username for different user types';
COMMENT ON CONSTRAINT user_authentication_username_user_type_key ON user_authentication IS 'Allows same username for different user types';
COMMENT ON FUNCTION create_user_with_auth IS 'Creates user with authentication, allows same username for different user types';
COMMENT ON FUNCTION check_username_availability IS 'Checks username availability for specific user type'; 