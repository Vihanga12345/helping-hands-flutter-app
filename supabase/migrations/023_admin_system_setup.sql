-- HELPING HANDS APP - ADMIN SYSTEM SETUP
-- ============================================================================
-- Migration: 023_admin_system_setup.sql
-- Purpose: Complete admin system implementation with authentication, job management, and analytics
-- Date: January 2025

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- STEP 1: ADMIN USERS TABLE
-- ============================================================================

-- Admin users table for system administrators
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMP,
    last_login TIMESTAMP,
    last_login_ip INET,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Insert default admin user (password: admin123, hashed with bcrypt)
INSERT INTO admin_users (username, password_hash, full_name, email) VALUES
('admin', '$2b$12$LQv3c1yqBWVHxkd0LQ4lVeEpMQppU6jnUnq9xwGJw7p.KdMT2NHAG', 'System Administrator', 'admin@helpinghands.com')
ON CONFLICT (username) DO NOTHING;

-- ============================================================================
-- STEP 2: ADMIN SESSIONS TABLE
-- ============================================================================

-- Admin session management
CREATE TABLE IF NOT EXISTS admin_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_user_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT true,
    last_activity TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- STEP 3: ADMIN AUDIT LOG TABLE
-- ============================================================================

-- Comprehensive audit logging for admin actions
CREATE TABLE IF NOT EXISTS admin_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_user_id UUID NOT NULL REFERENCES admin_users(id),
    action_type VARCHAR(50) NOT NULL, -- 'create', 'update', 'delete', 'view', 'login', 'logout'
    entity_type VARCHAR(50) NOT NULL, -- 'job', 'user', 'category', 'question', 'system'
    entity_id UUID,
    entity_name VARCHAR(200),
    action_details JSONB,
    old_values JSONB, -- Previous values for update operations
    new_values JSONB, -- New values for update/create operations
    ip_address INET,
    user_agent TEXT,
    session_id UUID REFERENCES admin_sessions(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- STEP 4: SYSTEM ANALYTICS TABLE
-- ============================================================================

-- Daily system metrics storage
CREATE TABLE IF NOT EXISTS system_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,2) NOT NULL,
    metric_date DATE NOT NULL,
    additional_data JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(metric_name, metric_date)
);

-- ============================================================================
-- STEP 5: ANALYTICS VIEWS FOR ADMIN DASHBOARD
-- ============================================================================

-- Daily job statistics view
CREATE OR REPLACE VIEW daily_job_stats AS
SELECT 
    DATE(created_at) as job_date,
    COUNT(*) as total_jobs,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_jobs,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_jobs,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_jobs,
    COUNT(CASE WHEN status IN ('accepted', 'started') THEN 1 END) as active_jobs,
    AVG(hourly_rate) as avg_hourly_rate,
    COALESCE(SUM(total_amount), 0) as total_revenue
FROM jobs
WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE(created_at)
ORDER BY job_date DESC;

-- User registration statistics view
CREATE OR REPLACE VIEW user_registration_stats AS
SELECT 
    DATE(created_at) as registration_date,
    user_type,
    COUNT(*) as registrations
FROM users
WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE(created_at), user_type
ORDER BY registration_date DESC, user_type;

-- Job category performance view
CREATE OR REPLACE VIEW category_performance_stats AS
SELECT 
    jc.name as category_name,
    COUNT(j.id) as total_jobs,
    COUNT(CASE WHEN j.status = 'completed' THEN 1 END) as completed_jobs,
    COUNT(CASE WHEN j.status = 'cancelled' THEN 1 END) as cancelled_jobs,
    ROUND(
        (COUNT(CASE WHEN j.status = 'completed' THEN 1 END)::DECIMAL / 
         NULLIF(COUNT(j.id), 0) * 100), 2
    ) as completion_rate,
    AVG(j.hourly_rate) as avg_hourly_rate,
    COALESCE(SUM(j.total_amount), 0) as total_revenue
FROM job_categories jc
LEFT JOIN jobs j ON jc.id = j.category_id
GROUP BY jc.id, jc.name
ORDER BY total_jobs DESC;

-- System overview statistics view
CREATE OR REPLACE VIEW system_overview_stats AS
SELECT 
    (SELECT COUNT(*) FROM users WHERE user_type = 'helper' AND is_active = true) as total_helpers,
    (SELECT COUNT(*) FROM users WHERE user_type = 'helpee' AND is_active = true) as total_helpees,
    (SELECT COUNT(*) FROM jobs) as total_jobs,
    (SELECT COUNT(*) FROM jobs WHERE status = 'completed') as completed_jobs,
    (SELECT COUNT(*) FROM jobs WHERE status IN ('pending', 'accepted', 'started')) as active_jobs,
    (SELECT COUNT(*) FROM jobs WHERE DATE(created_at) = CURRENT_DATE) as jobs_today,
    (SELECT COALESCE(SUM(total_amount), 0) FROM jobs WHERE status = 'completed') as total_revenue;

-- Recent admin activity view
CREATE OR REPLACE VIEW recent_admin_activity AS
SELECT 
    aal.id,
    au.username as admin_username,
    au.full_name as admin_name,
    aal.action_type,
    aal.entity_type,
    aal.entity_name,
    aal.action_details,
    aal.created_at
FROM admin_audit_log aal
JOIN admin_users au ON aal.admin_user_id = au.id
WHERE aal.created_at >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY aal.created_at DESC
LIMIT 100;

-- ============================================================================
-- STEP 6: ADMIN FUNCTIONS
-- ============================================================================

-- Function to authenticate admin user
CREATE OR REPLACE FUNCTION authenticate_admin(
    p_username VARCHAR(50),
    p_password_hash VARCHAR(255),
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
) RETURNS TABLE (
    success BOOLEAN,
    admin_id UUID,
    session_token VARCHAR(255),
    error_message TEXT
) AS $$
DECLARE
    admin_record RECORD;
    new_session_token VARCHAR(255);
    new_session_id UUID;
BEGIN
    -- Check if admin exists and is active
    SELECT * INTO admin_record
    FROM admin_users 
    WHERE username = p_username 
    AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::VARCHAR(255), 'Invalid username or password';
        RETURN;
    END IF;
    
    -- Check if account is locked
    IF admin_record.account_locked_until IS NOT NULL AND admin_record.account_locked_until > NOW() THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::VARCHAR(255), 'Account is temporarily locked';
        RETURN;
    END IF;
    
    -- Verify password (in real implementation, this should use proper bcrypt verification)
    IF admin_record.password_hash != p_password_hash THEN
        -- Increment failed login attempts
        UPDATE admin_users 
        SET failed_login_attempts = failed_login_attempts + 1,
            account_locked_until = CASE 
                WHEN failed_login_attempts >= 4 THEN NOW() + INTERVAL '30 minutes'
                ELSE account_locked_until
            END
        WHERE id = admin_record.id;
        
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::VARCHAR(255), 'Invalid username or password';
        RETURN;
    END IF;
    
    -- Generate session token
    new_session_token := encode(gen_random_bytes(32), 'hex');
    
    -- Create session
    INSERT INTO admin_sessions (
        admin_user_id, session_token, ip_address, user_agent, expires_at
    ) VALUES (
        admin_record.id, new_session_token, p_ip_address, p_user_agent, 
        NOW() + INTERVAL '8 hours'
    ) RETURNING id INTO new_session_id;
    
    -- Update admin login info
    UPDATE admin_users 
    SET last_login = NOW(),
        last_login_ip = p_ip_address,
        failed_login_attempts = 0,
        account_locked_until = NULL
    WHERE id = admin_record.id;
    
    -- Log the login
    INSERT INTO admin_audit_log (
        admin_user_id, action_type, entity_type, entity_id, action_details, 
        ip_address, user_agent, session_id
    ) VALUES (
        admin_record.id, 'login', 'system', admin_record.id, 
        jsonb_build_object('login_time', NOW(), 'username', p_username),
        p_ip_address, p_user_agent, new_session_id
    );
    
    RETURN QUERY SELECT TRUE, admin_record.id, new_session_token, NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate admin session
CREATE OR REPLACE FUNCTION validate_admin_session(
    p_session_token VARCHAR(255)
) RETURNS TABLE (
    is_valid BOOLEAN,
    admin_id UUID,
    admin_username VARCHAR(50),
    admin_name VARCHAR(100)
) AS $$
DECLARE
    session_record RECORD;
    admin_record RECORD;
BEGIN
    -- Check if session exists and is active
    SELECT * INTO session_record
    FROM admin_sessions 
    WHERE session_token = p_session_token 
    AND is_active = true 
    AND expires_at > NOW();
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::VARCHAR(50), NULL::VARCHAR(100);
        RETURN;
    END IF;
    
    -- Get admin details
    SELECT * INTO admin_record
    FROM admin_users 
    WHERE id = session_record.admin_user_id 
    AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::VARCHAR(50), NULL::VARCHAR(100);
        RETURN;
    END IF;
    
    -- Update last activity
    UPDATE admin_sessions 
    SET last_activity = NOW() 
    WHERE id = session_record.id;
    
    RETURN QUERY SELECT TRUE, admin_record.id, admin_record.username, admin_record.full_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log admin actions
CREATE OR REPLACE FUNCTION log_admin_action(
    p_admin_id UUID,
    p_session_token VARCHAR(255),
    p_action_type VARCHAR(50),
    p_entity_type VARCHAR(50),
    p_entity_id UUID DEFAULT NULL,
    p_entity_name VARCHAR(200) DEFAULT NULL,
    p_action_details JSONB DEFAULT NULL,
    p_old_values JSONB DEFAULT NULL,
    p_new_values JSONB DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    session_id UUID;
    log_id UUID;
BEGIN
    -- Get session ID
    SELECT id INTO session_id
    FROM admin_sessions 
    WHERE session_token = p_session_token 
    AND admin_user_id = p_admin_id
    AND is_active = true;
    
    -- Insert audit log
    INSERT INTO admin_audit_log (
        admin_user_id, action_type, entity_type, entity_id, entity_name,
        action_details, old_values, new_values, session_id
    ) VALUES (
        p_admin_id, p_action_type, p_entity_type, p_entity_id, p_entity_name,
        p_action_details, p_old_values, p_new_values, session_id
    ) RETURNING id INTO log_id;
    
    RETURN log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to logout admin session
CREATE OR REPLACE FUNCTION logout_admin_session(
    p_session_token VARCHAR(255)
) RETURNS BOOLEAN AS $$
DECLARE
    session_record RECORD;
BEGIN
    -- Get session details
    SELECT * INTO session_record
    FROM admin_sessions 
    WHERE session_token = p_session_token 
    AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Deactivate session
    UPDATE admin_sessions 
    SET is_active = false,
        last_activity = NOW()
    WHERE id = session_record.id;
    
    -- Log the logout
    INSERT INTO admin_audit_log (
        admin_user_id, action_type, entity_type, action_details, session_id
    ) VALUES (
        session_record.admin_user_id, 'logout', 'system', 
        jsonb_build_object('logout_time', NOW()),
        session_record.id
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get admin dashboard statistics
CREATE OR REPLACE FUNCTION get_admin_dashboard_stats()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_users', (SELECT total_helpers + total_helpees FROM system_overview_stats),
        'total_helpers', (SELECT total_helpers FROM system_overview_stats),
        'total_helpees', (SELECT total_helpees FROM system_overview_stats),
        'total_jobs', (SELECT total_jobs FROM system_overview_stats),
        'completed_jobs', (SELECT completed_jobs FROM system_overview_stats),
        'active_jobs', (SELECT active_jobs FROM system_overview_stats),
        'jobs_today', (SELECT jobs_today FROM system_overview_stats),
        'total_revenue', (SELECT total_revenue FROM system_overview_stats),
        'completion_rate', (
            CASE 
                WHEN (SELECT total_jobs FROM system_overview_stats) > 0 
                THEN ROUND((SELECT completed_jobs FROM system_overview_stats)::DECIMAL / (SELECT total_jobs FROM system_overview_stats) * 100, 2)
                ELSE 0
            END
        )
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STEP 7: INDEXES FOR PERFORMANCE
-- ============================================================================

-- Admin users indexes
CREATE INDEX IF NOT EXISTS idx_admin_users_username ON admin_users(username);
CREATE INDEX IF NOT EXISTS idx_admin_users_email ON admin_users(email);
CREATE INDEX IF NOT EXISTS idx_admin_users_active ON admin_users(is_active);

-- Admin sessions indexes
CREATE INDEX IF NOT EXISTS idx_admin_sessions_token ON admin_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_admin_id ON admin_sessions(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_active ON admin_sessions(is_active, expires_at);

-- Admin audit log indexes
CREATE INDEX IF NOT EXISTS idx_admin_audit_admin_id ON admin_audit_log(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_action_type ON admin_audit_log(action_type);
CREATE INDEX IF NOT EXISTS idx_admin_audit_entity_type ON admin_audit_log(entity_type);
CREATE INDEX IF NOT EXISTS idx_admin_audit_created_at ON admin_audit_log(created_at);
CREATE INDEX IF NOT EXISTS idx_admin_audit_entity_id ON admin_audit_log(entity_id);

-- System analytics indexes
CREATE INDEX IF NOT EXISTS idx_system_analytics_metric_date ON system_analytics(metric_name, metric_date);
CREATE INDEX IF NOT EXISTS idx_system_analytics_date ON system_analytics(metric_date);

-- ============================================================================
-- STEP 8: TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================================================

-- Trigger to update updated_at timestamp for admin_users
CREATE TRIGGER update_admin_users_updated_at 
    BEFORE UPDATE ON admin_users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update updated_at timestamp for system_analytics
CREATE TRIGGER update_system_analytics_updated_at 
    BEFORE UPDATE ON system_analytics 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- STEP 9: CLEANUP FUNCTION FOR OLD DATA
-- ============================================================================

-- Function to cleanup old sessions and logs
CREATE OR REPLACE FUNCTION cleanup_admin_data()
RETURNS VOID AS $$
BEGIN
    -- Remove expired sessions older than 7 days
    DELETE FROM admin_sessions 
    WHERE expires_at < NOW() - INTERVAL '7 days';
    
    -- Remove old audit logs older than 6 months
    DELETE FROM admin_audit_log 
    WHERE created_at < NOW() - INTERVAL '6 months';
    
    -- Remove old analytics data older than 2 years
    DELETE FROM system_analytics 
    WHERE metric_date < CURRENT_DATE - INTERVAL '2 years';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STEP 10: GRANT NECESSARY PERMISSIONS
-- ============================================================================

-- Grant permissions for admin functionality
-- Note: In production, you would grant these to a specific admin role
-- For development, we'll use the existing permissions structure

-- ============================================================================
-- MIGRATION VERIFICATION
-- ============================================================================

-- Verify all tables were created successfully
DO $$
BEGIN
    -- Check admin_users table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_users') THEN
        RAISE NOTICE '✅ admin_users table created successfully';
    ELSE
        RAISE EXCEPTION '❌ admin_users table not created';
    END IF;
    
    -- Check admin_sessions table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_sessions') THEN
        RAISE NOTICE '✅ admin_sessions table created successfully';
    ELSE
        RAISE EXCEPTION '❌ admin_sessions table not created';
    END IF;
    
    -- Check admin_audit_log table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_audit_log') THEN
        RAISE NOTICE '✅ admin_audit_log table created successfully';
    ELSE
        RAISE EXCEPTION '❌ admin_audit_log table not created';
    END IF;
    
    -- Check system_analytics table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'system_analytics') THEN
        RAISE NOTICE '✅ system_analytics table created successfully';
    ELSE
        RAISE EXCEPTION '❌ system_analytics table not created';
    END IF;
    
    -- Check views
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'daily_job_stats') THEN
        RAISE NOTICE '✅ daily_job_stats view created successfully';
    ELSE
        RAISE EXCEPTION '❌ daily_job_stats view not created';
    END IF;
    
    -- Check functions
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'authenticate_admin') THEN
        RAISE NOTICE '✅ authenticate_admin function created successfully';
    ELSE
        RAISE EXCEPTION '❌ authenticate_admin function not created';
    END IF;
    
    -- Check default admin user
    IF EXISTS (SELECT 1 FROM admin_users WHERE username = 'admin') THEN
        RAISE NOTICE '✅ Default admin user created successfully';
    ELSE
        RAISE EXCEPTION '❌ Default admin user not created';
    END IF;
    
    RAISE NOTICE '🎉 Admin system migration completed successfully!';
    RAISE NOTICE 'ℹ️  Default admin credentials: username=admin, password=admin123';
END $$; 