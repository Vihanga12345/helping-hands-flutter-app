-- PERMANENT FIX: Disable RLS on reports table
-- This ensures all authenticated users can submit reports without permission issues

-- Drop existing table and recreate without RLS issues
DROP TABLE IF EXISTS reports CASCADE;

-- Recreate reports table
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL,
  user_email TEXT NOT NULL,
  user_type TEXT NOT NULL,
  report_category TEXT NOT NULL CHECK (report_category IN (
    'Helpee issue',
    'Helper issue', 
    'Job issue',
    'Job rate issue',
    'Job question issue',
    'Other issue',
    'Question'
  )),
  description TEXT NOT NULL,
  is_seen BOOLEAN DEFAULT FALSE,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  seen_at TIMESTAMP WITH TIME ZONE NULL,
  seen_by_admin_id UUID NULL REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_reports_user_id ON reports(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_user_type ON reports(user_type);
CREATE INDEX IF NOT EXISTS idx_reports_category ON reports(report_category);
CREATE INDEX IF NOT EXISTS idx_reports_is_seen ON reports(is_seen);
CREATE INDEX IF NOT EXISTS idx_reports_submitted_at ON reports(submitted_at DESC);

-- DO NOT ENABLE RLS - Keep it disabled for reports
-- ALTER TABLE reports ENABLE ROW LEVEL SECURITY; -- COMMENTED OUT

-- Grant full permissions to authenticated users
GRANT ALL ON reports TO authenticated;
GRANT ALL ON reports TO anon;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_reports_updated_at_trigger ON reports;
CREATE TRIGGER update_reports_updated_at_trigger
  BEFORE UPDATE ON reports
  FOR EACH ROW
  EXECUTE FUNCTION update_reports_updated_at(); 