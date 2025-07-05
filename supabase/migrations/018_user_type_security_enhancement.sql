-- Migration: 018_user_type_security_enhancement.sql
-- Purpose: Implement user type-based security and route protection
-- Date: July 2025

-- 1. USER SESSIONS TABLE (Enhanced for user type tracking)
-- Check if user_sessions table already exists, if so add missing columns
DO $$ 
BEGIN
    -- Check if user_sessions table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_sessions') THEN
        -- Add missing columns if they don't exist (existing table uses user_auth_id)
        ALTER TABLE user_sessions ADD COLUMN IF NOT EXISTS user_type VARCHAR(20) CHECK (user_type IN ('helper', 'helpee', 'admin'));
        ALTER TABLE user_sessions ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        
        -- Check if we need to add user_id column (for compatibility)
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_sessions' AND column_name = 'user_id') THEN
            -- Add user_id column that references users table directly
            ALTER TABLE user_sessions ADD COLUMN user_id UUID REFERENCES users(id) ON DELETE CASCADE;
            
            -- Populate user_id from user_auth_id -> user_authentication -> users
            UPDATE user_sessions 
            SET user_id = ua.user_id 
            FROM user_authentication ua 
            WHERE user_sessions.user_auth_id = ua.id;
            
            RAISE NOTICE 'Added user_id column and populated from user_auth_id relationships';
        END IF;
        
        RAISE NOTICE 'Enhanced existing user_sessions table with user_type, last_activity_at, and user_id columns';
    ELSE
        -- Create new table if it doesn't exist (shouldn't happen, but just in case)
        CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_auth_id UUID NOT NULL REFERENCES user_authentication(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('helper', 'helpee', 'admin')),
    device_info TEXT,
    ip_address INET,
    user_agent TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
        RAISE NOTICE 'Created new user_sessions table';
    END IF;
END $$;

-- 2. SECURITY AUDIT LOG TABLE
CREATE TABLE IF NOT EXISTS security_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_token VARCHAR(255),
    event_type VARCHAR(50) NOT NULL, -- 'unauthorized_access', 'user_type_mismatch', 'session_hijack', 'forced_logout'
    attempted_route VARCHAR(255),
    expected_user_type VARCHAR(20),
    actual_user_type VARCHAR(20),
    ip_address INET,
    user_agent TEXT,
    event_details JSONB,
    severity VARCHAR(20) DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. USER TYPE SWITCHING LOG TABLE
CREATE TABLE IF NOT EXISTS user_type_switching_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    from_user_type VARCHAR(20),
    to_user_type VARCHAR(20) NOT NULL,
    switch_reason VARCHAR(100), -- 'registration', 'manual_switch', 'admin_change'
    ip_address INET,
    requires_reauth BOOLEAN DEFAULT TRUE,
    approved_by UUID REFERENCES users(id), -- For admin approvals
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. ROUTE PERMISSIONS TABLE
CREATE TABLE IF NOT EXISTS route_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_pattern VARCHAR(255) NOT NULL UNIQUE, -- '/helpee/*', '/helper/*', '/admin/*'
    allowed_user_types VARCHAR(20)[] NOT NULL, -- ['helpee'], ['helper'], ['admin']
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Add unique constraint to existing table if needed and insert default route permissions
DO $$
BEGIN
    -- Add unique constraint if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'route_permissions' 
        AND constraint_name = 'route_permissions_route_pattern_key'
    ) THEN
        ALTER TABLE route_permissions ADD CONSTRAINT route_permissions_route_pattern_key UNIQUE (route_pattern);
        RAISE NOTICE 'Added unique constraint to route_permissions.route_pattern';
    END IF;
END $$;

-- Insert default route permissions (now safe with unique constraint)
INSERT INTO route_permissions (route_pattern, allowed_user_types) VALUES
('/helpee/*', ARRAY['helpee']),
('/helper/*', ARRAY['helper']),
('/admin/*', ARRAY['admin']),
('/', ARRAY['helpee', 'helper', 'admin']),
('/intro*', ARRAY['helpee', 'helper', 'admin']),
('/user-selection', ARRAY['helpee', 'helper', 'admin']),
('/helpee-auth', ARRAY['helpee', 'helper', 'admin']),
('/helpee-login', ARRAY['helpee', 'helper', 'admin']),
('/helpee-register', ARRAY['helpee', 'helper', 'admin']),
('/helper-auth', ARRAY['helpee', 'helper', 'admin']),
('/helper-login', ARRAY['helpee', 'helper', 'admin']),
('/helper-register', ARRAY['helpee', 'helper', 'admin'])
ON CONFLICT (route_pattern) DO NOTHING;

-- 6. FUNCTIONS FOR USER TYPE VALIDATION

-- Function to validate user session and user type
CREATE OR REPLACE FUNCTION validate_user_session_and_type(
    p_session_token VARCHAR(255),
    p_required_user_type VARCHAR(20)
) RETURNS TABLE (
    is_valid BOOLEAN,
    user_id UUID,
    user_type VARCHAR(20),
    error_message TEXT
) AS $$
DECLARE
    session_record RECORD;
    user_record RECORD;
BEGIN
    -- Check if session exists and is active
    SELECT * INTO session_record
    FROM user_sessions 
    WHERE session_token = p_session_token 
    AND is_active = TRUE 
    AND expires_at > NOW();
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::VARCHAR(20), 'Invalid or expired session';
        RETURN;
    END IF;
    
    -- Get user details (handle both old and new schema)
    IF session_record.user_id IS NOT NULL THEN
        -- New schema with direct user_id reference
    SELECT * INTO user_record
    FROM users 
    WHERE id = session_record.user_id 
    AND is_active = TRUE;
    ELSE
        -- Old schema using user_auth_id
        SELECT u.* INTO user_record
        FROM users u
        JOIN user_authentication ua ON u.id = ua.user_id
        WHERE ua.id = session_record.user_auth_id 
        AND u.is_active = TRUE;
    END IF;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::VARCHAR(20), 'User not found or inactive';
        RETURN;
    END IF;
    
    -- Check user type match
    IF user_record.user_type != p_required_user_type THEN
        -- Log unauthorized access attempt
        INSERT INTO security_audit_log (
            user_id, session_token, event_type, attempted_route, 
            expected_user_type, actual_user_type, severity
        ) VALUES (
            user_record.id, p_session_token, 'user_type_mismatch', 
            'route_validation', p_required_user_type, user_record.user_type, 'high'
        );
        
        RETURN QUERY SELECT FALSE, user_record.id, user_record.user_type, 
            'User type mismatch: expected ' || p_required_user_type || ', got ' || user_record.user_type;
        RETURN;
    END IF;
    
    -- Update last activity
    UPDATE user_sessions 
    SET last_activity_at = NOW() 
    WHERE session_token = p_session_token;
    
    RETURN QUERY SELECT TRUE, user_record.id, user_record.user_type, NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check route permissions
CREATE OR REPLACE FUNCTION check_route_permission(
    p_route VARCHAR(255),
    p_user_type VARCHAR(20)
) RETURNS BOOLEAN AS $$
DECLARE
    permission_record RECORD;
BEGIN
    -- Check for exact match first
    SELECT * INTO permission_record
    FROM route_permissions 
    WHERE route_pattern = p_route 
    AND p_user_type = ANY(allowed_user_types)
    AND is_active = TRUE;
    
    IF FOUND THEN
        RETURN TRUE;
    END IF;
    
    -- Check for wildcard patterns
    SELECT * INTO permission_record
    FROM route_permissions 
    WHERE p_route LIKE REPLACE(route_pattern, '*', '%')
    AND p_user_type = ANY(allowed_user_types)
    AND is_active = TRUE;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log security events
CREATE OR REPLACE FUNCTION log_security_event(
    p_user_id UUID,
    p_session_token VARCHAR(255),
    p_event_type VARCHAR(50),
    p_attempted_route VARCHAR(255),
    p_expected_user_type VARCHAR(20),
    p_actual_user_type VARCHAR(20),
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_event_details JSONB DEFAULT NULL,
    p_severity VARCHAR(20) DEFAULT 'medium'
) RETURNS UUID AS $$
DECLARE
    log_id UUID;
BEGIN
    INSERT INTO security_audit_log (
        user_id, session_token, event_type, attempted_route,
        expected_user_type, actual_user_type, ip_address,
        user_agent, event_details, severity
    ) VALUES (
        p_user_id, p_session_token, p_event_type, p_attempted_route,
        p_expected_user_type, p_actual_user_type, p_ip_address,
        p_user_agent, p_event_details, p_severity
    ) RETURNING id INTO log_id;
    
    RETURN log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to invalidate user sessions (for forced logout)
CREATE OR REPLACE FUNCTION invalidate_user_sessions(
    p_user_id UUID,
    p_reason VARCHAR(100) DEFAULT 'security_policy'
) RETURNS INTEGER AS $$
DECLARE
    affected_count INTEGER;
BEGIN
    -- Handle both old and new schema
    UPDATE user_sessions 
    SET is_active = FALSE,
        last_activity_at = NOW()
    WHERE (
        (user_id IS NOT NULL AND user_id = p_user_id) OR
        (user_id IS NULL AND user_auth_id IN (
            SELECT id FROM user_authentication WHERE user_id = p_user_id
        ))
    )
    AND is_active = TRUE;
    
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    
    -- Log the forced logout
    INSERT INTO security_audit_log (
        user_id, event_type, event_details, severity
    ) VALUES (
        p_user_id, 'forced_logout', 
        jsonb_build_object('reason', p_reason, 'sessions_invalidated', affected_count),
        'high'
    );
    
    RETURN affected_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_auth_id ON user_sessions(user_auth_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_active ON user_sessions(is_active, expires_at);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_type ON user_sessions(user_type);

CREATE INDEX IF NOT EXISTS idx_security_audit_user_id ON security_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_security_audit_event_type ON security_audit_log(event_type);
CREATE INDEX IF NOT EXISTS idx_security_audit_severity ON security_audit_log(severity);
CREATE INDEX IF NOT EXISTS idx_security_audit_created_at ON security_audit_log(created_at);

CREATE INDEX IF NOT EXISTS idx_route_permissions_pattern ON route_permissions(route_pattern);
CREATE INDEX IF NOT EXISTS idx_route_permissions_user_types ON route_permissions USING GIN(allowed_user_types);

-- 8. TRIGGERS FOR AUTOMATIC CLEANUP

-- Trigger to clean up expired sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions() RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM user_sessions 
    WHERE expires_at < NOW() - INTERVAL '1 day';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to run cleanup on session insert
DROP TRIGGER IF EXISTS trigger_cleanup_expired_sessions ON user_sessions;
CREATE TRIGGER trigger_cleanup_expired_sessions
    AFTER INSERT ON user_sessions
    EXECUTE FUNCTION cleanup_expired_sessions();

-- 9. SECURITY POLICIES (Optional RLS for future use)
-- Note: These are commented out for development but can be enabled for production

-- ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE security_audit_log ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE user_type_switching_log ENABLE ROW LEVEL SECURITY;

-- CREATE POLICY user_sessions_policy ON user_sessions
--     FOR ALL TO authenticated
--     USING (user_id = auth.uid());

-- CREATE POLICY security_audit_admin_only ON security_audit_log
--     FOR ALL TO authenticated
--     USING (EXISTS (
--         SELECT 1 FROM users 
--         WHERE id = auth.uid() 
--         AND user_type = 'admin'
--     ));

-- 10. GRANT PERMISSIONS
-- Grant necessary permissions to the application user
-- GRANT USAGE ON SCHEMA public TO your_app_user;
-- GRANT SELECT, INSERT, UPDATE ON user_sessions TO your_app_user;
-- GRANT SELECT, INSERT ON security_audit_log TO your_app_user;
-- GRANT SELECT, INSERT ON user_type_switching_log TO your_app_user;
-- GRANT SELECT ON route_permissions TO your_app_user;

COMMENT ON TABLE user_sessions IS 'Enhanced user sessions with user type tracking and security features';
COMMENT ON TABLE security_audit_log IS 'Audit trail for security events and unauthorized access attempts';
COMMENT ON TABLE user_type_switching_log IS 'Log of user type changes for audit purposes';
COMMENT ON TABLE route_permissions IS 'Route-based permissions for user type access control';

COMMENT ON FUNCTION validate_user_session_and_type IS 'Validates user session and checks user type authorization';
COMMENT ON FUNCTION check_route_permission IS 'Checks if a user type has permission to access a specific route';
COMMENT ON FUNCTION log_security_event IS 'Logs security events for audit purposes';
COMMENT ON FUNCTION invalidate_user_sessions IS 'Invalidates all active sessions for a user (forced logout)'; 

-- ============================================================================
-- MIGRATION VERIFICATION
-- ============================================================================

-- Verify the migration completed successfully
DO $$
BEGIN
    -- Check if user_sessions table has the required columns
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_sessions' AND column_name = 'user_type') THEN
        RAISE NOTICE '✅ user_sessions.user_type column exists';
    ELSE
        RAISE EXCEPTION '❌ user_sessions.user_type column missing';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_sessions' AND column_name = 'last_activity_at') THEN
        RAISE NOTICE '✅ user_sessions.last_activity_at column exists';
    ELSE
        RAISE EXCEPTION '❌ user_sessions.last_activity_at column missing';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_sessions' AND column_name = 'user_id') THEN
        RAISE NOTICE '✅ user_sessions.user_id column exists (backwards compatibility)';
    ELSE
        RAISE NOTICE 'ℹ️ user_sessions.user_id column not added (using existing user_auth_id)';
    END IF;
    
    -- Check if security tables exist
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'security_audit_log') THEN
        RAISE NOTICE '✅ security_audit_log table exists';
    ELSE
        RAISE EXCEPTION '❌ security_audit_log table missing';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'route_permissions') THEN
        RAISE NOTICE '✅ route_permissions table exists';
    ELSE
        RAISE EXCEPTION '❌ route_permissions table missing';
    END IF;
    
    -- Check if functions exist
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'validate_user_session_and_type') THEN
        RAISE NOTICE '✅ validate_user_session_and_type function exists';
    ELSE
        RAISE EXCEPTION '❌ validate_user_session_and_type function missing';
    END IF;
    
    RAISE NOTICE '🎉 Migration 018_user_type_security_enhancement completed successfully!';
END $$;