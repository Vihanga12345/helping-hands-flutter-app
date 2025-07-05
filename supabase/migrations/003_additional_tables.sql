-- Additional tables and updates for dynamic data integration

-- Add missing columns to users table for complete profile data
ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(20) DEFAULT 'English';
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_currency VARCHAR(10) DEFAULT 'LKR';
ALTER TABLE users ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_completion_percentage INTEGER DEFAULT 0;

-- Create ratings and reviews table
CREATE TABLE IF NOT EXISTS ratings_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    reviewer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reviewee_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    review_type VARCHAR(20) CHECK (review_type IN ('helpee_to_helper', 'helper_to_helpee')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user statistics view for helpees
CREATE OR REPLACE VIEW helpee_statistics AS
SELECT 
    u.id as user_id,
    u.first_name,
    u.last_name,
    u.created_at as member_since,
    COALESCE(job_stats.total_jobs, 0) as total_jobs,
    COALESCE(job_stats.pending_jobs, 0) as pending_jobs,
    COALESCE(job_stats.ongoing_jobs, 0) as ongoing_jobs,
    COALESCE(job_stats.completed_jobs, 0) as completed_jobs,
    COALESCE(rating_stats.avg_rating, 0.0) as average_rating,
    COALESCE(rating_stats.total_reviews, 0) as total_reviews
FROM users u
LEFT JOIN (
    SELECT 
        helpee_id,
        COUNT(*) as total_jobs,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_jobs,
        COUNT(CASE WHEN status IN ('accepted', 'started') THEN 1 END) as ongoing_jobs,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_jobs
    FROM jobs 
    GROUP BY helpee_id
) job_stats ON u.id = job_stats.helpee_id
LEFT JOIN (
    SELECT 
        reviewee_id,
        AVG(rating::DECIMAL) as avg_rating,
        COUNT(*) as total_reviews
    FROM ratings_reviews 
    WHERE review_type = 'helper_to_helpee'
    GROUP BY reviewee_id
) rating_stats ON u.id = rating_stats.reviewee_id
WHERE u.user_type = 'helpee';

-- Create user statistics view for helpers
CREATE OR REPLACE VIEW helper_statistics AS
SELECT 
    u.id as user_id,
    u.first_name,
    u.last_name,
    u.created_at as member_since,
    COALESCE(job_stats.total_jobs, 0) as total_jobs,
    COALESCE(job_stats.pending_jobs, 0) as pending_jobs,
    COALESCE(job_stats.ongoing_jobs, 0) as ongoing_jobs,
    COALESCE(job_stats.completed_jobs, 0) as completed_jobs,
    COALESCE(rating_stats.avg_rating, 0.0) as average_rating,
    COALESCE(rating_stats.total_reviews, 0) as total_reviews
FROM users u
LEFT JOIN (
    SELECT 
        assigned_helper_id,
        COUNT(*) as total_jobs,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_jobs,
        COUNT(CASE WHEN status IN ('accepted', 'started') THEN 1 END) as ongoing_jobs,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_jobs
    FROM jobs 
    WHERE assigned_helper_id IS NOT NULL
    GROUP BY assigned_helper_id
) job_stats ON u.id = job_stats.assigned_helper_id
LEFT JOIN (
    SELECT 
        reviewee_id,
        AVG(rating::DECIMAL) as avg_rating,
        COUNT(*) as total_reviews
    FROM ratings_reviews 
    WHERE review_type = 'helpee_to_helper'
    GROUP BY reviewee_id
) rating_stats ON u.id = rating_stats.reviewee_id
WHERE u.user_type = 'helper';

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_ratings_reviews_job_id ON ratings_reviews(job_id);
CREATE INDEX IF NOT EXISTS idx_ratings_reviews_reviewer_id ON ratings_reviews(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_ratings_reviews_reviewee_id ON ratings_reviews(reviewee_id);
CREATE INDEX IF NOT EXISTS idx_jobs_helpee_status ON jobs(helpee_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_helper_status ON jobs(assigned_helper_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_scheduled_date ON jobs(scheduled_date);

-- Add sample ratings for testing
INSERT INTO ratings_reviews (job_id, reviewer_id, reviewee_id, rating, review_text, review_type) 
SELECT 
    j.id,
    j.helpee_id,
    j.assigned_helper_id,
    (RANDOM() * 2 + 3)::INTEGER, -- Random rating between 3-5
    'Great service!',
    'helpee_to_helper'
FROM jobs j 
WHERE j.assigned_helper_id IS NOT NULL 
AND j.status = 'completed'
AND NOT EXISTS (
    SELECT 1 FROM ratings_reviews rr 
    WHERE rr.job_id = j.id AND rr.review_type = 'helpee_to_helper'
)
LIMIT 10;

-- Update trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_ratings_reviews_updated_at 
    BEFORE UPDATE ON ratings_reviews 
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column(); 