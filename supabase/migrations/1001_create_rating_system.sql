-- ============================================================================
-- HELPER RESTRICTION FEATURE: Add jobs_visible column to users table
-- ============================================================================
-- This migration adds the jobs_visible column to control whether helpers
-- can see new job requests. Admins can toggle this setting.
-- 
-- When jobs_visible = true: Helper can see all new jobs (default behavior)
-- When jobs_visible = false: Helper cannot see new jobs but can continue ongoing work
-- ============================================================================

-- Add jobs_visible column to users table
ALTER TABLE public.users 
ADD COLUMN jobs_visible BOOLEAN NOT NULL DEFAULT true;

-- Create index for performance when filtering jobs by visibility
CREATE INDEX IF NOT EXISTS idx_users_jobs_visible 
ON public.users(jobs_visible) 
WHERE user_type = 'helper';

-- Add comment to document the column purpose
COMMENT ON COLUMN public.users.jobs_visible IS 'Controls whether helpers can see new job requests. Only admins can modify this setting. Default: true';

-- ============================================================================
-- UPDATE EXISTING HELPER RECORDS
-- ============================================================================
-- Ensure all existing helpers have jobs_visible set to true (enabled by default)
UPDATE public.users 
SET jobs_visible = true 
WHERE user_type = 'helper' AND jobs_visible IS NULL;

-- ============================================================================
-- VERIFICATION QUERIES (for testing)
-- ============================================================================
-- Uncomment these to verify the migration worked correctly:

-- SELECT COUNT(*) as total_helpers FROM users WHERE user_type = 'helper';
-- SELECT COUNT(*) as visible_helpers FROM users WHERE user_type = 'helper' AND jobs_visible = true;
-- SELECT COUNT(*) as restricted_helpers FROM users WHERE user_type = 'helper' AND jobs_visible = false;

-- ============================================================================
-- ROLLBACK INSTRUCTIONS (if needed)
-- ============================================================================
-- To rollback this migration, run:
-- DROP INDEX IF EXISTS idx_users_jobs_visible;
-- ALTER TABLE public.users DROP COLUMN IF EXISTS jobs_visible; 