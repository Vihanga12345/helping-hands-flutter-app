-- Migration: Create Rating System
-- File: 1001_create_rating_system.sql

-- Add average_rating column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS average_rating DECIMAL(3,2) DEFAULT 0.00;

-- Create ratings table to store individual ratings
CREATE TABLE IF NOT EXISTS ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    rater_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rated_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    
    -- Ensure one rating per user per job
    UNIQUE(job_id, rater_id, rated_user_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_ratings_rated_user_id ON ratings(rated_user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_job_id ON ratings(job_id);
CREATE INDEX IF NOT EXISTS idx_ratings_rater_id ON ratings(rater_id);

-- Function to calculate and update average rating for a user
CREATE OR REPLACE FUNCTION update_user_average_rating(user_id UUID)
RETURNS VOID AS $$
DECLARE
    avg_rating DECIMAL(3,2);
BEGIN
    -- Calculate average rating for the user
    SELECT COALESCE(AVG(rating), 0.00)
    INTO avg_rating
    FROM ratings
    WHERE rated_user_id = user_id;
    
    -- Update user's average rating
    UPDATE users
    SET average_rating = avg_rating,
        updated_at = NOW()
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to submit a rating and update averages
CREATE OR REPLACE FUNCTION submit_rating(
    p_job_id UUID,
    p_rater_id UUID,
    p_rated_user_id UUID,
    p_rating INTEGER,
    p_review_text TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    rating_id UUID;
    result JSON;
BEGIN
    -- Validate rating range
    IF p_rating < 1 OR p_rating > 5 THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Rating must be between 1 and 5'
        );
    END IF;
    
    -- Insert or update rating
    INSERT INTO ratings (job_id, rater_id, rated_user_id, rating, review_text)
    VALUES (p_job_id, p_rater_id, p_rated_user_id, p_rating, p_review_text)
    ON CONFLICT (job_id, rater_id, rated_user_id)
    DO UPDATE SET 
        rating = EXCLUDED.rating,
        review_text = EXCLUDED.review_text,
        updated_at = NOW()
    RETURNING id INTO rating_id;
    
    -- Update the rated user's average rating
    PERFORM update_user_average_rating(p_rated_user_id);
    
    result := json_build_object(
        'success', true,
        'message', 'Rating submitted successfully',
        'rating_id', rating_id
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'message', 'Error submitting rating: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

-- Function to get ratings for a user
CREATE OR REPLACE FUNCTION get_user_ratings(user_id UUID)
RETURNS TABLE (
    id UUID,
    job_id UUID,
    rater_name TEXT,
    rater_id UUID,
    rating INTEGER,
    review_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    job_title TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        r.job_id,
        rater.full_name as rater_name,
        r.rater_id,
        r.rating,
        r.review_text,
        r.created_at,
        j.title as job_title
    FROM ratings r
    JOIN users rater ON r.rater_id = rater.id
    JOIN jobs j ON r.job_id = j.id
    WHERE r.rated_user_id = user_id
    ORDER BY r.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to check if rating exists for a job and user combination
CREATE OR REPLACE FUNCTION check_rating_exists(
    p_job_id UUID,
    p_rater_id UUID,
    p_rated_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    rating_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM ratings 
        WHERE job_id = p_job_id 
        AND rater_id = p_rater_id 
        AND rated_user_id = p_rated_user_id
    ) INTO rating_exists;
    
    RETURN rating_exists;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update average rating when ratings change
CREATE OR REPLACE FUNCTION trigger_update_average_rating()
RETURNS TRIGGER AS $$
BEGIN
    -- Update average rating for the rated user
    PERFORM update_user_average_rating(COALESCE(NEW.rated_user_id, OLD.rated_user_id));
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS update_average_rating_trigger ON ratings;
CREATE TRIGGER update_average_rating_trigger
    AFTER INSERT OR UPDATE OR DELETE ON ratings
    FOR EACH ROW EXECUTE FUNCTION trigger_update_average_rating();

-- Add comments for documentation
COMMENT ON TABLE ratings IS 'Stores user ratings and reviews for completed jobs';
COMMENT ON COLUMN ratings.rating IS 'Star rating from 1 to 5';
COMMENT ON COLUMN ratings.review_text IS 'Optional text review/comment';
COMMENT ON COLUMN users.average_rating IS 'Calculated average rating from all received ratings'; 