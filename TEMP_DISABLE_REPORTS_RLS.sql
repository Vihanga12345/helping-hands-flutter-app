-- TEMPORARY FIX: Disable RLS on reports table for testing
-- This will allow report submissions to work while we debug the RLS issue

-- Disable Row Level Security on reports table
ALTER TABLE reports DISABLE ROW LEVEL SECURITY;

-- Grant permissions to authenticated users
GRANT ALL ON reports TO authenticated;
GRANT ALL ON reports TO anon;

-- You can re-enable RLS later with:
-- ALTER TABLE reports ENABLE ROW LEVEL SECURITY; 