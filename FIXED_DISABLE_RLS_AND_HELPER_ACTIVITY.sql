-- FIXED: DISABLE ALL RLS AND FIX HELPER ACTIVITY ISSUES
-- Run this in Supabase Dashboard SQL Editor

-- ================================
-- 1. DISABLE RLS ON EXISTING TABLES ONLY
-- ================================

-- Disable RLS on users table
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Allow insert during sign up" ON public.users;
DROP POLICY IF EXISTS "Public read access for users" ON public.users;
DROP POLICY IF EXISTS "Users can insert themselves" ON public.users;
DROP POLICY IF EXISTS "Users can update themselves" ON public.users;

-- Disable RLS on jobs table
ALTER TABLE IF EXISTS public.jobs DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Helpees can create jobs" ON public.jobs;
DROP POLICY IF EXISTS "Helpees can view their own jobs" ON public.jobs;
DROP POLICY IF EXISTS "Helpers can view available jobs" ON public.jobs;
DROP POLICY IF EXISTS "Helpers can update assigned jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users can view jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users can create jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users can update jobs" ON public.jobs;

-- Disable RLS on notifications table
ALTER TABLE IF EXISTS public.notifications DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON public.notifications;
DROP POLICY IF EXISTS "Allow read for authenticated users" ON public.notifications;
DROP POLICY IF EXISTS "Allow update for authenticated users" ON public.notifications;

-- Disable RLS on job_categories table
ALTER TABLE IF EXISTS public.job_categories DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view job categories" ON public.job_categories;
DROP POLICY IF EXISTS "Public read access" ON public.job_categories;

-- Disable RLS on other tables if they exist
DO $$
BEGIN
    -- Check and disable RLS on job_ignores if it exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'job_ignores' AND table_schema = 'public') THEN
        ALTER TABLE public.job_ignores DISABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "Helpers can manage their own ignores" ON public.job_ignores;
    END IF;

    -- Check and disable RLS on ratings if it exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'ratings' AND table_schema = 'public') THEN
        ALTER TABLE public.ratings DISABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "Users can view ratings" ON public.ratings;
        DROP POLICY IF EXISTS "Users can create ratings" ON public.ratings;
    END IF;

    -- Check and disable RLS on job_ratings if it exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'job_ratings' AND table_schema = 'public') THEN
        ALTER TABLE public.job_ratings DISABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "Users can view job ratings" ON public.job_ratings;
        DROP POLICY IF EXISTS "Users can create job ratings" ON public.job_ratings;
    END IF;

    -- Check and disable RLS on payments if it exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'payments' AND table_schema = 'public') THEN
        ALTER TABLE public.payments DISABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "Users can view their payments" ON public.payments;
        DROP POLICY IF EXISTS "Users can create payments" ON public.payments;
    END IF;

    -- Check and disable RLS on job_applications if it exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'job_applications' AND table_schema = 'public') THEN
        ALTER TABLE public.job_applications DISABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS "Helpers can apply to jobs" ON public.job_applications;
        DROP POLICY IF EXISTS "Users can view applications" ON public.job_applications;
    END IF;
END $$;

-- ================================
-- 2. GRANT PERMISSIONS ON EXISTING TABLES
-- ================================

-- Grant all permissions to public (anonymous users) and authenticated users
GRANT ALL ON public.users TO anon, authenticated;
GRANT ALL ON public.jobs TO anon, authenticated;
GRANT ALL ON public.notifications TO anon, authenticated;
GRANT ALL ON public.job_categories TO anon, authenticated;

-- Grant permissions on other tables if they exist
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'job_ignores' AND table_schema = 'public') THEN
        GRANT ALL ON public.job_ignores TO anon, authenticated;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'ratings' AND table_schema = 'public') THEN
        GRANT ALL ON public.ratings TO anon, authenticated;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'job_ratings' AND table_schema = 'public') THEN
        GRANT ALL ON public.job_ratings TO anon, authenticated;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'payments' AND table_schema = 'public') THEN
        GRANT ALL ON public.payments TO anon, authenticated;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'job_applications' AND table_schema = 'public') THEN
        GRANT ALL ON public.job_applications TO anon, authenticated;
    END IF;
END $$;

-- Grant sequence permissions
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Grant function execution permissions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- ================================
-- 3. ADD MISSING COLUMNS IF NOT EXISTS
-- ================================

-- Add profile_picture_url if missing
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'profile_picture_url') THEN
        ALTER TABLE public.users ADD COLUMN profile_picture_url TEXT;
        RAISE NOTICE 'Added profile_picture_url column to users table';
    ELSE
        RAISE NOTICE 'profile_picture_url column already exists in users table';
    END IF;
END $$;

-- Add bio column if missing
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'bio') THEN
        ALTER TABLE public.users ADD COLUMN bio TEXT;
        RAISE NOTICE 'Added bio column to users table';
    ELSE
        RAISE NOTICE 'bio column already exists in users table';
    END IF;
END $$;

-- Add total_amount column if missing
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'jobs' AND column_name = 'total_amount') THEN
        ALTER TABLE public.jobs ADD COLUMN total_amount DECIMAL(10,2);
        RAISE NOTICE 'Added total_amount column to jobs table';
    ELSE
        RAISE NOTICE 'total_amount column already exists in jobs table';
    END IF;
END $$;

-- ================================
-- 4. DROP AND RECREATE HELPER STATISTICS FUNCTION
-- ================================

-- Drop existing function first
DROP FUNCTION IF EXISTS get_helper_statistics(UUID);
DROP FUNCTION IF EXISTS get_helper_statistics(TEXT);

-- Create new helper statistics function
CREATE OR REPLACE FUNCTION get_helper_statistics(p_helper_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
    job_count INTEGER := 0;
    completed_jobs INTEGER := 0;
    total_earnings DECIMAL := 0;
    avg_rating DECIMAL := 0;
    pending_jobs INTEGER := 0;
    ongoing_jobs INTEGER := 0;
BEGIN
    -- Count total jobs assigned to helper
    SELECT COUNT(*) INTO job_count
    FROM jobs 
    WHERE assigned_helper_id = p_helper_id;
    
    -- Count completed jobs
    SELECT COUNT(*) INTO completed_jobs
    FROM jobs 
    WHERE assigned_helper_id = p_helper_id AND status = 'completed';
    
    -- Count pending jobs
    SELECT COUNT(*) INTO pending_jobs
    FROM jobs 
    WHERE assigned_helper_id = p_helper_id AND status = 'pending';
    
    -- Count ongoing jobs
    SELECT COUNT(*) INTO ongoing_jobs
    FROM jobs 
    WHERE assigned_helper_id = p_helper_id AND status IN ('accepted', 'ongoing', 'started');
    
    -- Calculate total earnings from completed jobs
    SELECT COALESCE(SUM(total_amount), 0) INTO total_earnings
    FROM jobs 
    WHERE assigned_helper_id = p_helper_id AND status = 'completed';
    
    -- Calculate average rating (if job_ratings table exists)
    BEGIN
        IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'job_ratings' AND table_schema = 'public') THEN
            SELECT COALESCE(AVG(rating), 0) INTO avg_rating
            FROM job_ratings 
            WHERE helper_id = p_helper_id;
        ELSE
            avg_rating := 0;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        avg_rating := 0;
    END;
    
    -- Build result JSON
    result := json_build_object(
        'total_jobs', job_count,
        'completed_jobs', completed_jobs,
        'pending_jobs', pending_jobs,
        'ongoing_jobs', ongoing_jobs,
        'total_earnings', total_earnings,
        'average_rating', avg_rating,
        'completion_rate', CASE WHEN job_count > 0 THEN (completed_jobs::DECIMAL / job_count * 100) ELSE 0 END
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================
-- 5. DROP AND RECREATE HELPEE STATISTICS FUNCTION
-- ================================

-- Drop existing function first
DROP FUNCTION IF EXISTS get_helpee_statistics(UUID);
DROP FUNCTION IF EXISTS get_helpee_statistics(TEXT);

-- Create new helpee statistics function
CREATE OR REPLACE FUNCTION get_helpee_statistics(p_helpee_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
    total_requests INTEGER := 0;
    completed_requests INTEGER := 0;
    total_spent DECIMAL := 0;
    pending_requests INTEGER := 0;
    ongoing_requests INTEGER := 0;
BEGIN
    -- Count total job requests by helpee
    SELECT COUNT(*) INTO total_requests
    FROM jobs 
    WHERE helpee_id = p_helpee_id;
    
    -- Count completed requests
    SELECT COUNT(*) INTO completed_requests
    FROM jobs 
    WHERE helpee_id = p_helpee_id AND status = 'completed';
    
    -- Count pending requests
    SELECT COUNT(*) INTO pending_requests
    FROM jobs 
    WHERE helpee_id = p_helpee_id AND status = 'pending';
    
    -- Count ongoing requests
    SELECT COUNT(*) INTO ongoing_requests
    FROM jobs 
    WHERE helpee_id = p_helpee_id AND status IN ('accepted', 'ongoing', 'started');
    
    -- Calculate total amount spent on completed jobs
    SELECT COALESCE(SUM(total_amount), 0) INTO total_spent
    FROM jobs 
    WHERE helpee_id = p_helpee_id AND status = 'completed';
    
    -- Build result JSON
    result := json_build_object(
        'total_requests', total_requests,
        'completed_requests', completed_requests,
        'pending_requests', pending_requests,
        'ongoing_requests', ongoing_requests,
        'total_spent', total_spent,
        'completion_rate', CASE WHEN total_requests > 0 THEN (completed_requests::DECIMAL / total_requests * 100) ELSE 0 END
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================
-- 6. UPDATE NOTIFICATIONS TABLE CONSTRAINTS
-- ================================

-- Remove any constraints that might cause RLS issues
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'notifications' AND table_schema = 'public') THEN
        ALTER TABLE notifications ALTER COLUMN user_id DROP NOT NULL;
        ALTER TABLE notifications ALTER COLUMN notification_type SET DEFAULT 'general';
        RAISE NOTICE 'Updated notifications table constraints';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Could not update notifications constraints: %', SQLERRM;
END $$;

-- ================================
-- 7. CREATE INDEXES FOR BETTER PERFORMANCE
-- ================================

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_helper_status ON jobs(assigned_helper_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_helpee_status ON jobs(helpee_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_scheduled_date ON jobs(scheduled_date);

-- Create notification index if table exists
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'notifications' AND table_schema = 'public') THEN
        CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
    END IF;
END $$;

-- ================================
-- VERIFICATION QUERIES
-- ================================

-- Check RLS status on all tables
SELECT 
    schemaname,
    tablename,
    rowsecurity as "RLS Enabled"
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- Count pending jobs for testing
SELECT 
    status,
    COUNT(*) as count
FROM jobs 
GROUP BY status
ORDER BY status;

-- Check if required columns exist
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'jobs')
AND column_name IN ('profile_picture_url', 'bio', 'total_amount')
ORDER BY table_name, column_name;

SELECT 'All RLS policies have been disabled and helper activity issues have been fixed!' as message; 