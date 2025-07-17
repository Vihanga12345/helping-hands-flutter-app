-- =============================================
-- REAL-TIME NOTIFICATION TRIGGERS ENHANCEMENT
-- File: 040_realtime_notification_triggers.sql
-- Date: 2025
-- Purpose: Comprehensive notification triggers for real-time notifications
-- =============================================

-- Enable real-time for notifications table
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- Enable real-time for jobs table (for live updates)
ALTER PUBLICATION supabase_realtime ADD TABLE jobs;

-- Enable real-time for payments table (for payment updates)  
ALTER PUBLICATION supabase_realtime ADD TABLE payments;

-- =============================================
-- STEP 1: Create Enhanced Notification Functions
-- =============================================

-- Drop existing notification functions to avoid conflicts
DROP FUNCTION IF EXISTS create_job_notification(UUID, TEXT, TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS notify_job_status_change();
DROP FUNCTION IF EXISTS notify_payment_status_change();

-- Create comprehensive notification creation function
CREATE OR REPLACE FUNCTION create_notification(
    p_user_id UUID,
    p_title TEXT,
    p_message TEXT,
    p_notification_type TEXT,
    p_related_job_id UUID DEFAULT NULL,
    p_related_user_id UUID DEFAULT NULL,
    p_action_url TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    INSERT INTO notifications (
        user_id,
        title,
        message,
        notification_type,
        related_job_id,
        related_user_id,
        action_url,
        is_read,
        created_at
    ) VALUES (
        p_user_id,
        p_title,
        p_message,
        p_notification_type,
        p_related_job_id,
        p_related_user_id,
        p_action_url,
        false,
        NOW()
    ) RETURNING id INTO v_notification_id;

    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- STEP 2: Job Status Change Notification Function
-- =============================================

CREATE OR REPLACE FUNCTION notify_job_status_change()
RETURNS TRIGGER AS $$
DECLARE
    v_helper_name TEXT;
    v_helpee_name TEXT;
    v_job_title TEXT;
    v_notification_id UUID;
BEGIN
    -- Get helper and helpee names and job title
    SELECT 
        helper.display_name,
        helpee.display_name,
        j.title
    INTO v_helper_name, v_helpee_name, v_job_title
    FROM jobs j
    LEFT JOIN users helper ON j.assigned_helper_id = helper.id
    LEFT JOIN users helpee ON j.helpee_id = helpee.id
    WHERE j.id = NEW.id;

    -- Handle different status changes
    CASE NEW.status
        WHEN 'accepted' THEN
            -- Notify helpee that job was accepted
            SELECT create_notification(
                NEW.helpee_id,
                'Job Request Accepted! ✅',
                COALESCE(v_helper_name, 'A helper') || ' has accepted your job request for "' || COALESCE(v_job_title, 'your job') || '". They will contact you soon.',
                'job_accepted',
                NEW.id,
                NEW.assigned_helper_id,
                '/job-details/' || NEW.id
            ) INTO v_notification_id;

            -- Notify helper about job acceptance
            IF NEW.assigned_helper_id IS NOT NULL THEN
                SELECT create_notification(
                    NEW.assigned_helper_id,
                    'Job Request Accepted! 📋',
                    'You have successfully accepted the job request for "' || COALESCE(v_job_title, 'a job') || '" from ' || COALESCE(v_helpee_name, 'a helpee') || '.',
                    'job_accepted',
                    NEW.id,
                    NEW.helpee_id,
                    '/job-details/' || NEW.id
                ) INTO v_notification_id;
            END IF;

        WHEN 'rejected' THEN
            -- Only notify helpee about rejection (no specific helper assigned)
            SELECT create_notification(
                NEW.helpee_id,
                'Job Request Update ❌',
                'Your job request for "' || COALESCE(v_job_title, 'your job') || '" was not accepted this time. Don''t worry, other helpers may still respond.',
                'job_rejected',
                NEW.id,
                NULL,
                '/job-details/' || NEW.id
            ) INTO v_notification_id;

        WHEN 'ongoing' THEN
            -- Notify both parties that job has started
            SELECT create_notification(
                NEW.helpee_id,
                'Job Started! 🚀',
                COALESCE(v_helper_name, 'Your helper') || ' has started working on "' || COALESCE(v_job_title, 'your job') || '".',
                'job_started',
                NEW.id,
                NEW.assigned_helper_id,
                '/job-details/' || NEW.id
            ) INTO v_notification_id;

            IF NEW.assigned_helper_id IS NOT NULL THEN
                SELECT create_notification(
                    NEW.assigned_helper_id,
                    'Job Started! 🚀',
                    'You have started working on "' || COALESCE(v_job_title, 'the job') || '" for ' || COALESCE(v_helpee_name, 'your client') || '.',
                    'job_started',
                    NEW.id,
                    NEW.helpee_id,
                    '/job-details/' || NEW.id
                ) INTO v_notification_id;
            END IF;

        WHEN 'paused' THEN
            -- Notify both parties that job is paused
            SELECT create_notification(
                NEW.helpee_id,
                'Job Paused ⏸️',
                'The job "' || COALESCE(v_job_title, 'your job') || '" has been paused by ' || COALESCE(v_helper_name, 'your helper') || '.',
                'job_paused',
                NEW.id,
                NEW.assigned_helper_id,
                '/job-details/' || NEW.id
            ) INTO v_notification_id;

            IF NEW.assigned_helper_id IS NOT NULL THEN
                SELECT create_notification(
                    NEW.assigned_helper_id,
                    'Job Paused ⏸️',
                    'You have paused the job "' || COALESCE(v_job_title, 'the job') || '".',
                    'job_paused',
                    NEW.id,
                    NEW.helpee_id,
                    '/job-details/' || NEW.id
                ) INTO v_notification_id;
            END IF;

        WHEN 'completed' THEN
            -- Notify both parties about job completion with payment instructions
            SELECT create_notification(
                NEW.helpee_id,
                'Job Completed! 🎉',
                COALESCE(v_helper_name, 'Your helper') || ' has completed "' || COALESCE(v_job_title, 'your job') || '". Please review the work and process payment of $' || COALESCE(NEW.total_amount::TEXT, '0') || '.',
                'job_completed',
                NEW.id,
                NEW.assigned_helper_id,
                '/job-details/' || NEW.id
            ) INTO v_notification_id;

            IF NEW.assigned_helper_id IS NOT NULL THEN
                SELECT create_notification(
                    NEW.assigned_helper_id,
                    'Job Completed! 🎉',
                    'You have successfully completed "' || COALESCE(v_job_title, 'the job') || '" for ' || COALESCE(v_helpee_name, 'your client') || '. You should receive $' || COALESCE(NEW.total_amount::TEXT, '0') || ' once payment is processed.',
                    'job_completed',
                    NEW.id,
                    NEW.helpee_id,
                    '/job-details/' || NEW.id
                ) INTO v_notification_id;
            END IF;

        WHEN 'cancelled' THEN
            -- Notify both parties about cancellation
            SELECT create_notification(
                NEW.helpee_id,
                'Job Cancelled ❌',
                'The job "' || COALESCE(v_job_title, 'your job') || '" has been cancelled.',
                'job_cancelled',
                NEW.id,
                NEW.assigned_helper_id,
                '/job-details/' || NEW.id
            ) INTO v_notification_id;

            IF NEW.assigned_helper_id IS NOT NULL THEN
                SELECT create_notification(
                    NEW.assigned_helper_id,
                    'Job Cancelled ❌',
                    'The job "' || COALESCE(v_job_title, 'the job') || '" has been cancelled by the client.',
                    'job_cancelled',
                    NEW.id,
                    NEW.helpee_id,
                    '/job-details/' || NEW.id
                ) INTO v_notification_id;
            END IF;

        ELSE
            -- Handle any other status changes
            NULL;
    END CASE;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- STEP 3: Payment Status Change Notification Function
-- =============================================

CREATE OR REPLACE FUNCTION notify_payment_status_change()
RETURNS TRIGGER AS $$
DECLARE
    v_job_title TEXT;
    v_helper_name TEXT;
    v_helpee_name TEXT;
    v_notification_id UUID;
BEGIN
    -- Get job and user details
    SELECT 
        j.title,
        helper.display_name,
        helpee.display_name
    INTO v_job_title, v_helper_name, v_helpee_name
    FROM payments p
    JOIN jobs j ON p.job_id = j.id
    LEFT JOIN users helper ON p.payee_id = helper.id
    LEFT JOIN users helpee ON p.payer_id = helpee.id
    WHERE p.id = NEW.id;

    -- Handle different payment status changes
    CASE NEW.payment_status
        WHEN 'completed' THEN
            -- Notify helper about payment received
            SELECT create_notification(
                NEW.payee_id,
                'Payment Received! 💰',
                'You have received $' || NEW.amount::TEXT || ' for completing "' || COALESCE(v_job_title, 'the job') || '".',
                'payment_received',
                NEW.job_id,
                NEW.payer_id,
                '/earnings'
            ) INTO v_notification_id;

            -- Notify helpee about payment processed
            SELECT create_notification(
                NEW.payer_id,
                'Payment Processed! ✅',
                'Your payment of $' || NEW.amount::TEXT || ' for "' || COALESCE(v_job_title, 'the job') || '" has been processed successfully.',
                'payment_processed',
                NEW.job_id,
                NEW.payee_id,
                '/payment-history'
            ) INTO v_notification_id;

        WHEN 'failed' THEN
            -- Notify helpee about payment failure
            SELECT create_notification(
                NEW.payer_id,
                'Payment Failed ❌',
                'Your payment of $' || NEW.amount::TEXT || ' for "' || COALESCE(v_job_title, 'the job') || '" failed to process. Please try again.',
                'payment_failed',
                NEW.job_id,
                NEW.payee_id,
                '/job-details/' || NEW.job_id
            ) INTO v_notification_id;

        WHEN 'refunded' THEN
            -- Notify helpee about refund
            SELECT create_notification(
                NEW.payer_id,
                'Payment Refunded 💸',
                'Your payment of $' || NEW.amount::TEXT || ' for "' || COALESCE(v_job_title, 'the job') || '" has been refunded.',
                'payment_refunded',
                NEW.job_id,
                NEW.payee_id,
                '/payment-history'
            ) INTO v_notification_id;

        ELSE
            -- Handle any other payment status changes
            NULL;
    END CASE;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- STEP 4: Rating and Review Notification Function
-- =============================================

CREATE OR REPLACE FUNCTION notify_rating_received()
RETURNS TRIGGER AS $$
DECLARE
    v_job_title TEXT;
    v_reviewer_name TEXT;
    v_notification_id UUID;
BEGIN
    -- Get job title and reviewer name
    SELECT 
        j.title,
        reviewer.display_name
    INTO v_job_title, v_reviewer_name
    FROM jobs j
    LEFT JOIN users reviewer ON NEW.reviewer_id = reviewer.id
    WHERE j.id = NEW.job_id;

    -- Notify the person who received the rating
    SELECT create_notification(
        NEW.reviewee_id,
        'New Rating Received! ⭐',
        COALESCE(v_reviewer_name, 'Someone') || ' rated your work ' || NEW.rating || ' stars for "' || COALESCE(v_job_title, 'a job') || '".' || 
        CASE WHEN NEW.review_text IS NOT NULL AND LENGTH(NEW.review_text) > 0 
             THEN ' They also left a review.' 
             ELSE '' 
        END,
        'rating_received',
        NEW.job_id,
        NEW.reviewer_id,
        '/profile'
    ) INTO v_notification_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- STEP 5: Create Triggers
-- =============================================

-- Drop existing triggers to avoid conflicts
DROP TRIGGER IF EXISTS job_status_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS payment_status_notification_trigger ON payments;
DROP TRIGGER IF EXISTS rating_notification_trigger ON ratings_reviews;

-- Create job status change trigger
CREATE TRIGGER job_status_notification_trigger
    AFTER UPDATE OF status ON jobs
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION notify_job_status_change();

-- Create payment status change trigger  
CREATE TRIGGER payment_status_notification_trigger
    AFTER UPDATE OF payment_status ON payments
    FOR EACH ROW
    WHEN (OLD.payment_status IS DISTINCT FROM NEW.payment_status)
    EXECUTE FUNCTION notify_payment_status_change();

-- Create rating received trigger
CREATE TRIGGER rating_notification_trigger
    AFTER INSERT ON ratings_reviews
    FOR EACH ROW
    EXECUTE FUNCTION notify_rating_received();

-- =============================================
-- STEP 6: Create Helper Functions for Real-time Updates
-- =============================================

-- Function to manually trigger notifications (for testing or manual triggers)
CREATE OR REPLACE FUNCTION trigger_test_notification(
    p_user_id UUID,
    p_notification_type TEXT DEFAULT 'test'
) RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    SELECT create_notification(
        p_user_id,
        'Test Notification 🧪',
        'This is a test notification to verify the real-time system is working correctly.',
        p_notification_type,
        NULL,
        NULL,
        NULL
    ) INTO v_notification_id;

    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql;

-- Function to create job application notifications
CREATE OR REPLACE FUNCTION notify_job_application()
RETURNS TRIGGER AS $$
DECLARE
    v_job_title TEXT;
    v_helper_name TEXT;
    v_notification_id UUID;
BEGIN
    -- Get job title and helper name
    SELECT 
        j.title,
        helper.display_name
    INTO v_job_title, v_helper_name
    FROM jobs j
    LEFT JOIN users helper ON NEW.helper_id = helper.id
    WHERE j.id = NEW.job_id;

    -- Only notify on new applications
    IF TG_OP = 'INSERT' THEN
        -- Notify job owner (helpee) about new application
        SELECT create_notification(
            (SELECT helpee_id FROM jobs WHERE id = NEW.job_id),
            'New Job Application! 📨',
            COALESCE(v_helper_name, 'A helper') || ' has applied for your job "' || COALESCE(v_job_title, 'your job') || '".',
            'job_application',
            NEW.job_id,
            NEW.helper_id,
            '/job-applications/' || NEW.job_id
        ) INTO v_notification_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create job application trigger
DROP TRIGGER IF EXISTS job_application_notification_trigger ON job_applications;
CREATE TRIGGER job_application_notification_trigger
    AFTER INSERT ON job_applications
    FOR EACH ROW
    EXECUTE FUNCTION notify_job_application();

-- =============================================
-- STEP 7: Add Indexes for Performance
-- =============================================

-- Index for notifications real-time queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_related_job ON notifications(related_job_id);

-- Index for jobs real-time queries
CREATE INDEX IF NOT EXISTS idx_jobs_status_updated ON jobs(status, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_helpee_status ON jobs(helpee_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_helper_status ON jobs(assigned_helper_id, status);

-- =============================================
-- STEP 8: Enable Row Level Security (Optional - for enhanced security)
-- =============================================

-- Enable RLS on notifications table (users can only see their own notifications)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own notifications
CREATE POLICY notifications_user_policy ON notifications
    FOR ALL USING (auth.uid() = user_id);

-- Policy: Users can insert notifications (for system notifications)
CREATE POLICY notifications_insert_policy ON notifications
    FOR INSERT WITH CHECK (true);

-- =============================================
-- COMPLETION CONFIRMATION
-- =============================================

-- Insert a confirmation record
DO $$
BEGIN
    RAISE NOTICE '✅ Real-time notification triggers have been successfully installed!';
    RAISE NOTICE '📋 Features enabled:';
    RAISE NOTICE '   - Job status change notifications';
    RAISE NOTICE '   - Payment status notifications';
    RAISE NOTICE '   - Rating and review notifications';
    RAISE NOTICE '   - Job application notifications';
    RAISE NOTICE '   - Real-time database subscriptions';
    RAISE NOTICE '   - Performance indexes';
    RAISE NOTICE '   - Row Level Security';
    RAISE NOTICE '🚀 Real-time notification system is now active!';
END $$; 