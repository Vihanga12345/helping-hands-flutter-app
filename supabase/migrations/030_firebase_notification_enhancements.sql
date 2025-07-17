-- HELPING HANDS APP - Firebase Notification Enhancements
-- ============================================================================
-- Migration 030: Add notification system tables and triggers
-- Date: January 2025
-- Purpose: Set up comprehensive notification system with Firebase integration

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- STEP 1: Create Notification Tables
-- ============================================================================

-- Notification templates table
CREATE TABLE IF NOT EXISTS notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title_en VARCHAR(100) NOT NULL,
    body_en TEXT NOT NULL,
    title_si VARCHAR(100),
    body_si TEXT,
    title_ta VARCHAR(100),
    body_ta TEXT,
    notification_type VARCHAR(50) NOT NULL CHECK (notification_type IN (
        'payment_due',
        'job_completed',
        'payment_received',
        'system_maintenance',
        'new_rating',
        'job_request_rejected',
        'job_paused',
        'app_update',
        'job_request_accepted',
        'rate_experience',
        'job_started',
        'new_job_request',
        'job_resumed'
    )),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User notification preferences table
CREATE TABLE IF NOT EXISTS user_notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    payment_notifications BOOLEAN DEFAULT true,
    job_status_notifications BOOLEAN DEFAULT true,
    rating_notifications BOOLEAN DEFAULT true,
    system_notifications BOOLEAN DEFAULT true,
    email_notifications BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User FCM tokens table
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_info TEXT,
    is_active BOOLEAN DEFAULT true,
    last_used TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, fcm_token)
);

-- Notification history table
CREATE TABLE IF NOT EXISTS notification_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    template_id UUID NOT NULL REFERENCES notification_templates(id),
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(100) NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    sent_via VARCHAR(20)[] DEFAULT ARRAY['push'],
    sent_at TIMESTAMP DEFAULT NOW(),
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- STEP 2: Create Notification Functions
-- ============================================================================

-- Function to send notification
CREATE OR REPLACE FUNCTION send_notification(
    p_user_id UUID,
    
    p_notification_type VARCHAR(50),
    p_data JSONB DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_template_id UUID;
    v_notification_id UUID;
    v_user_language VARCHAR(2);
    v_title VARCHAR(100);
    v_body TEXT;
    v_user_prefs RECORD;
BEGIN
    -- Get user's language preference (default to English)
    SELECT COALESCE(language_preference, 'en') INTO v_user_language
    FROM users WHERE id = p_user_id;

    -- Get notification template
    SELECT id INTO v_template_id
    FROM notification_templates
    WHERE notification_type = p_notification_type
    AND is_active = true
    LIMIT 1;

    IF v_template_id IS NULL THEN
        RAISE EXCEPTION 'No active template found for notification type: %', p_notification_type;
    END IF;

    -- Get user notification preferences
    SELECT * INTO v_user_prefs
    FROM user_notification_preferences
    WHERE user_id = p_user_id;

    -- Set title and body based on language
    CASE v_user_language
        WHEN 'si' THEN
            SELECT title_si, body_si INTO v_title, v_body
            FROM notification_templates
            WHERE id = v_template_id;
        WHEN 'ta' THEN
            SELECT title_ta, body_ta INTO v_title, v_body
            FROM notification_templates
            WHERE id = v_template_id;
        ELSE
            SELECT title_en, body_en INTO v_title, v_body
            FROM notification_templates
            WHERE id = v_template_id;
    END CASE;

    -- If translated title/body not available, fall back to English
    IF v_title IS NULL THEN
        SELECT title_en INTO v_title
        FROM notification_templates
        WHERE id = v_template_id;
    END IF;

    IF v_body IS NULL THEN
        SELECT body_en INTO v_body
        FROM notification_templates
        WHERE id = v_template_id;
    END IF;

    -- Create notification history record
    INSERT INTO notification_history (
        user_id,
        template_id,
        notification_type,
        title,
        body,
        data,
        sent_via
    ) VALUES (
        p_user_id,
        v_template_id,
        p_notification_type,
        v_title,
        v_body,
        p_data,
        ARRAY['push']::VARCHAR(20)[]
    ) RETURNING id INTO v_notification_id;

    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- STEP 3: Create Notification Triggers
-- ============================================================================

-- Trigger function for job status changes
CREATE OR REPLACE FUNCTION notify_job_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only proceed if status has changed
    IF (TG_OP = 'UPDATE' AND OLD.status = NEW.status) THEN
        RETURN NEW;
    END IF;

    -- Send notifications based on status change
    CASE NEW.status
        WHEN 'accepted' THEN
            -- Notify helpee
            PERFORM send_notification(
                NEW.helpee_id,
                'job_request_accepted',
                jsonb_build_object('job_id', NEW.id)
            );
        WHEN 'rejected' THEN
            -- Notify helpee
            PERFORM send_notification(
                NEW.helpee_id,
                'job_request_rejected',
                jsonb_build_object('job_id', NEW.id)
            );
        WHEN 'started' THEN
            -- Notify both parties
            PERFORM send_notification(
                NEW.helpee_id,
                'job_started',
                jsonb_build_object('job_id', NEW.id)
            );
            PERFORM send_notification(
                NEW.assigned_helper_id,
                'job_started',
                jsonb_build_object('job_id', NEW.id)
            );
        WHEN 'paused' THEN
            -- Notify both parties
            PERFORM send_notification(
                NEW.helpee_id,
                'job_paused',
                jsonb_build_object('job_id', NEW.id)
            );
            PERFORM send_notification(
                NEW.assigned_helper_id,
                'job_paused',
                jsonb_build_object('job_id', NEW.id)
            );
        WHEN 'resumed' THEN
            -- Notify both parties
            PERFORM send_notification(
                NEW.helpee_id,
                'job_resumed',
                jsonb_build_object('job_id', NEW.id)
            );
            PERFORM send_notification(
                NEW.assigned_helper_id,
                'job_resumed',
                jsonb_build_object('job_id', NEW.id)
            );
        WHEN 'completed' THEN
            -- Notify both parties
            PERFORM send_notification(
                NEW.helpee_id,
                'job_completed',
                jsonb_build_object('job_id', NEW.id)
            );
            PERFORM send_notification(
                NEW.assigned_helper_id,
                'job_completed',
                jsonb_build_object('job_id', NEW.id)
            );
    END CASE;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for job status changes
DROP TRIGGER IF EXISTS job_status_notification_trigger ON jobs;
CREATE TRIGGER job_status_notification_trigger
    AFTER UPDATE OF status ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION notify_job_status_change();

-- ============================================================================
-- STEP 4: Insert Default Notification Templates
-- ============================================================================

-- Insert notification templates
INSERT INTO notification_templates (
    title_en, body_en,
    title_si, body_si,
    title_ta, body_ta,
    notification_type
) VALUES
    (
        'Payment Due',
        'Payment is due for your completed job',
        'ගෙවීම් කල යුතුයි',
        'ඔබගේ සම්පූර්ණ කරන ලද රැකියාව සඳහා ගෙවීම් කල යුතුය',
        'கட்டணம் செலுத்த வேண்டும்',
        'உங்கள் முடிக்கப்பட்ட வேலைக்கு கட்டணம் செலுத்த வேண்டும்',
        'payment_due'
    ),
    (
        'Job Completed',
        'Your job has been completed',
        'රැකියාව සම්පූර්ණයි',
        'ඔබගේ රැකියාව සම්පූර්ණ කර ඇත',
        'வேலை முடிந்தது',
        'உங்கள் வேலை முடிக்கப்பட்டது',
        'job_completed'
    ),
    (
        'Payment Received',
        'Payment has been received for your job',
        'ගෙවීම ලැබී ඇත',
        'ඔබගේ රැකියාව සඳහා ගෙවීම ලැබී ඇත',
        'பணம் பெறப்பட்டது',
        'உங்கள் வேலைக்கான கட்டணம் பெறப்பட்டது',
        'payment_received'
    ),
    (
        'System Maintenance',
        'The app will undergo maintenance',
        'පද්ධති නඩත්තුව',
        'යෙදුම නඩත්තු කටයුතු සඳහා යටත් වනු ඇත',
        'அமைப்பு பராமரிப்பு',
        'பயன்பாடு பராமரிப்புக்கு உட்படும்',
        'system_maintenance'
    ),
    (
        'New Rating',
        'You have received a new rating',
        'නව ඇගයීමක්',
        'ඔබට නව ඇගයීමක් ලැබී ඇත',
        'புதிய மதிப்பீடு',
        'நீங்கள் புதிய மதிப்பீட்டைப் பெற்றுள்ளீர்கள்',
        'new_rating'
    ),
    (
        'Job Request Rejected',
        'Your job request has been rejected',
        'රැකියා ඉල්ලීම ප්‍රතික්ෂේප විය',
        'ඔබගේ රැකියා ඉල්ලීම ප්‍රතික්ෂේප කර ඇත',
        'வேலை கோரிக்கை நிராகரிக்கப்பட்டது',
        'உங்கள் வேலை கோரிக்கை நிராகரிக்கப்பட்டது',
        'job_request_rejected'
    ),
    (
        'Job Paused',
        'Your job has been paused',
        'රැකියාව නතර කර ඇත',
        'ඔබගේ රැකියාව තාවකාලිකව නතර කර ඇත',
        'வேலை இடைநிறுத்தப்பட்டது',
        'உங்கள் வேலை இடைநிறுத்தப்பட்டுள்ளது',
        'job_paused'
    ),
    (
        'App Update Available',
        'A new version of the app is available',
        'යෙදුම් යාවත්කාලීනයක් තිබේ',
        'යෙදුමේ නව අනුවාදයක් තිබේ',
        'பயன்பாட்டு புதுப்பிப்பு கிடைக்கிறது',
        'பயன்பாட்டின் புதிய பதிப்பு கிடைக்கிறது',
        'app_update'
    ),
    (
        'Job Request Accepted',
        'Your job request has been accepted',
        'රැකියා ඉල්ලීම පිළිගෙන ඇත',
        'ඔබගේ රැකියා ඉල්ලීම පිළිගෙන ඇත',
        'வேலை கோரிக்கை ஏற்கப்பட்டது',
        'உங்கள் வேலை கோரிக்கை ஏற்கப்பட்டது',
        'job_request_accepted'
    ),
    (
        'Rate Your Experience',
        'Please rate your recent job experience',
        'ඔබගේ අත්දැකීම ඇගයීම',
        'කරුණාකර ඔබගේ මෑත රැකියා අත්දැකීම ඇගයන්න',
        'உங்கள் அனுபவத்தை மதிப்பிடவும்',
        'உங்கள் சமீபத்திய வேலை அனுபவத்தை மதிப்பிடவும்',
        'rate_experience'
    ),
    (
        'Job Started',
        'Your job has been started',
        'රැකියාව ආරම්භ විය',
        'ඔබගේ රැකියාව ආරම්භ කර ඇත',
        'வேலை தொடங்கியது',
        'உங்கள் வேலை தொடங்கப்பட்டது',
        'job_started'
    ),
    (
        'New Job Request',
        'You have received a new job request',
        'නව රැකියා ඉල්ලීමක්',
        'ඔබට නව රැකියා ඉල්ලීමක් ලැබී ඇත',
        'புதிய வேலை கோரிக்கை',
        'நீங்கள் புதிய வேலை கோரிக்கையைப் பெற்றுள்ளீர்கள்',
        'new_job_request'
    ),
    (
        'Job Resumed',
        'Your job has been resumed',
        'රැකියාව නැවත ආරම්භ විය',
        'ඔබගේ රැකියාව නැවත ආරම්භ කර ඇත',
        'வேலை மீண்டும் தொடங்கியது',
        'உங்கள் வேலை மீண்டும் தொடங்கப்பட்டது',
        'job_resumed'
    );

-- ============================================================================
-- STEP 5: Create Default User Preferences
-- ============================================================================

-- Function to create default notification preferences for new users
CREATE OR REPLACE FUNCTION create_default_notification_preferences()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_notification_preferences (user_id)
    VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new user notification preferences
DROP TRIGGER IF EXISTS create_notification_preferences_trigger ON users;
CREATE TRIGGER create_notification_preferences_trigger
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION create_default_notification_preferences();

-- ============================================================================
-- STEP 6: Create Indexes for Performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_notification_history_user ON notification_history(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_history_type ON notification_history(notification_type);
CREATE INDEX IF NOT EXISTS idx_notification_history_created ON notification_history(created_at);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user ON user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_active ON user_fcm_tokens(is_active);
CREATE INDEX IF NOT EXISTS idx_notification_templates_type ON notification_templates(notification_type);
CREATE INDEX IF NOT EXISTS idx_user_notification_prefs_user ON user_notification_preferences(user_id);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$ 
BEGIN
    -- Verify tables exist
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name IN (
            'notification_templates',
            'user_notification_preferences',
            'user_fcm_tokens',
            'notification_history'
        )
    ) THEN
        RAISE NOTICE '✅ Notification tables created successfully';
    ELSE
        RAISE EXCEPTION '❌ Some notification tables are missing';
    END IF;

    -- Verify triggers exist
    IF EXISTS (
        SELECT 1 FROM information_schema.triggers
        WHERE trigger_name IN (
            'job_status_notification_trigger',
            'create_notification_preferences_trigger'
        )
    ) THEN
        RAISE NOTICE '✅ Notification triggers created successfully';
    ELSE
        RAISE EXCEPTION '❌ Some notification triggers are missing';
    END IF;

    -- Verify templates exist
    IF EXISTS (SELECT 1 FROM notification_templates LIMIT 1) THEN
        RAISE NOTICE '✅ Notification templates inserted successfully';
    ELSE
        RAISE EXCEPTION '❌ No notification templates found';
    END IF;

    RAISE NOTICE '🎉 Migration 030_firebase_notification_enhancements completed successfully!';
END $$; 