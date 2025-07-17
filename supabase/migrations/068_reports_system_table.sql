-- Create reports table for user reporting system
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL,
  user_email TEXT NOT NULL,
  user_type TEXT NOT NULL CHECK (user_type IN ('helpee', 'helper', 'admin')),
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

-- Enable RLS (Row Level Security)
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only see their own reports
CREATE POLICY "Users can view own reports" ON reports
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own reports
CREATE POLICY "Users can create own reports" ON reports
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Admins can view all reports
CREATE POLICY "Admins can view all reports" ON reports
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.user_type = 'admin'
    )
  );

-- Admins can update reports (mark as seen)
CREATE POLICY "Admins can update reports" ON reports
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.user_type = 'admin'
    )
  );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_reports_updated_at_trigger
  BEFORE UPDATE ON reports
  FOR EACH ROW
  EXECUTE FUNCTION update_reports_updated_at();

-- Insert sample data for testing (optional)
-- Note: This would need real user IDs from your users table
-- INSERT INTO reports (user_id, user_name, user_email, user_type, report_category, description)
-- VALUES 
--   ('sample-user-id', 'John Doe', 'john@example.com', 'helpee', 'Job issue', 'Sample report description'); 