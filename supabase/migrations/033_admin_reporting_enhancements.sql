-- Function to check if a user is an admin
CREATE OR REPLACE FUNCTION public.is_admin(user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = user_id AND user_type = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhance existing job_reports table
ALTER TABLE job_reports ADD COLUMN IF NOT EXISTS report_category VARCHAR(50);
ALTER TABLE job_reports ADD COLUMN IF NOT EXISTS priority_level VARCHAR(20) DEFAULT 'medium';
ALTER TABLE job_reports ADD COLUMN IF NOT EXISTS admin_response TEXT;
ALTER TABLE job_reports ADD COLUMN IF NOT EXISTS resolution_details TEXT;

-- Create user reports table
CREATE TABLE IF NOT EXISTS user_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES users(id),
    reported_user_id UUID NOT NULL REFERENCES users(id),
    report_type VARCHAR(50) NOT NULL,
    report_description TEXT NOT NULL,
    evidence_urls TEXT[],
    status VARCHAR(20) DEFAULT 'pending', -- pending, investigating, resolved
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create general reports table for system-wide issues
CREATE TABLE IF NOT EXISTS general_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES users(id), -- Can be null for anonymous reports
    report_type VARCHAR(50) NOT NULL,
    subject VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium',
    status VARCHAR(20) DEFAULT 'open', -- open, in_progress, closed
    admin_response TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for new tables
ALTER TABLE user_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE general_reports ENABLE ROW LEVEL SECURITY;

-- Policies for user_reports
CREATE POLICY "Admins can manage all user reports"
ON user_reports FOR ALL
USING (public.is_admin(auth.uid()));

CREATE POLICY "Users can create reports"
ON user_reports FOR INSERT
WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can view their own reported cases"
ON user_reports FOR SELECT
USING (auth.uid() = reporter_id);

-- Policies for general_reports
CREATE POLICY "Admins can manage all general reports"
ON general_reports FOR ALL
USING (public.is_admin(auth.uid()));

CREATE POLICY "Authenticated users can create general reports"
ON general_reports FOR INSERT
WITH CHECK (auth.role() = 'authenticated'); 