-- Migration: 068_enhanced_ai_chatbot_system.sql
-- Description: Enhanced AI chatbot system with conversation state, job drafts, and reporting
-- Created: 2024-12-20
-- NOTE: Works with admin-customizable job categories - no hardcoded job types

-- Create conversation sessions table to track ongoing chats
CREATE TABLE IF NOT EXISTS ai_conversation_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  session_id TEXT UNIQUE NOT NULL, -- Dialogflow session ID
  current_step TEXT NOT NULL DEFAULT 'greeting', -- greeting, job_selection, questions, location, description, review
  collected_data JSONB NOT NULL DEFAULT '{}', -- All collected information
  job_category_id UUID REFERENCES job_categories(id), -- Links to admin-created categories
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create job request drafts table for incomplete requests
CREATE TABLE IF NOT EXISTS ai_job_request_drafts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  session_id TEXT REFERENCES ai_conversation_sessions(session_id) ON DELETE CASCADE,
  job_category_id UUID REFERENCES job_categories(id), -- Links to admin-created categories
  title TEXT, -- AI-generated title
  description TEXT, -- Collected requirements
  location_address TEXT,
  location_latitude DECIMAL(10, 8),
  location_longitude DECIMAL(11, 8),
  preferred_date DATE,
  preferred_time TIME,
  estimated_duration INTEGER, -- in minutes
  hourly_rate DECIMAL(10, 2),
  special_requirements JSONB DEFAULT '{}', -- Answers to job-specific questions
  is_complete BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create unknown job requests table for reporting
CREATE TABLE IF NOT EXISTS ai_unknown_job_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  requested_job_type TEXT NOT NULL,
  user_description TEXT,
  session_id TEXT,
  status TEXT DEFAULT 'pending', -- pending, reviewed, implemented, rejected
  admin_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add job aliases for fuzzy matching (admin-manageable)
CREATE TABLE IF NOT EXISTS ai_job_aliases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_category_id UUID NOT NULL REFERENCES job_categories(id) ON DELETE CASCADE,
  alias TEXT NOT NULL,
  confidence_score FLOAT DEFAULT 1.0, -- 0-1 similarity score
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster alias matching
CREATE INDEX IF NOT EXISTS idx_ai_job_aliases_alias ON ai_job_aliases USING GIN(to_tsvector('english', alias));
CREATE INDEX IF NOT EXISTS idx_ai_job_aliases_category ON ai_job_aliases(job_category_id);

-- Add RLS policies
ALTER TABLE ai_conversation_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_job_request_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_unknown_job_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_job_aliases ENABLE ROW LEVEL SECURITY;

-- Conversation sessions policies
CREATE POLICY "Users can manage their own conversation sessions" ON ai_conversation_sessions
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anonymous users can create conversation sessions" ON ai_conversation_sessions
  FOR INSERT WITH CHECK (true);

-- Job request drafts policies  
CREATE POLICY "Users can manage their own job request drafts" ON ai_job_request_drafts
  FOR ALL USING (auth.uid() = user_id);

-- Unknown job requests policies
CREATE POLICY "Users can create unknown job requests" ON ai_unknown_job_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own unknown job requests" ON ai_unknown_job_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all unknown job requests" ON ai_unknown_job_requests
  FOR ALL USING (auth.role() = 'authenticated' AND EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND user_type = 'admin'
  ));

-- Job aliases policies
CREATE POLICY "Anyone can read job aliases" ON ai_job_aliases
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage job aliases" ON ai_job_aliases
  FOR ALL USING (auth.role() = 'authenticated' AND EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND user_type = 'admin'
  ));

-- Create functions for conversation management

-- Function to find matching job categories with fuzzy matching
CREATE OR REPLACE FUNCTION find_matching_job_categories(search_term TEXT)
RETURNS TABLE (
  category_id UUID,
  category_name TEXT,
  confidence FLOAT,
  match_type TEXT,
  hourly_rate DECIMAL,
  questions JSONB
) 
LANGUAGE plpgsql
AS $$
BEGIN
  -- First try exact match on category names
  RETURN QUERY
  SELECT 
    jc.id as category_id,
    jc.name as category_name,
    1.0 as confidence,
    'exact' as match_type,
    jc.base_hourly_rate as hourly_rate,
    COALESCE(jc.default_questions, '[]'::jsonb) as questions
  FROM job_categories jc
  WHERE jc.is_active = true 
    AND LOWER(jc.name) = LOWER(search_term);
  
  -- If no exact match, try aliases
  IF NOT FOUND THEN
    RETURN QUERY
    SELECT 
      jc.id as category_id,
      jc.name as category_name,
      aja.confidence_score as confidence,
      'alias' as match_type,
      jc.base_hourly_rate as hourly_rate,
      COALESCE(jc.default_questions, '[]'::jsonb) as questions
    FROM ai_job_aliases aja
    JOIN job_categories jc ON jc.id = aja.job_category_id
    WHERE jc.is_active = true 
      AND LOWER(aja.alias) ILIKE '%' || LOWER(search_term) || '%'
    ORDER BY aja.confidence_score DESC
    LIMIT 3;
  END IF;
  
  -- If still no match, try partial matching on category names
  IF NOT FOUND THEN
    RETURN QUERY
    SELECT 
      jc.id as category_id,
      jc.name as category_name,
      0.5 as confidence,
      'partial' as match_type,
      jc.base_hourly_rate as hourly_rate,
      COALESCE(jc.default_questions, '[]'::jsonb) as questions
    FROM job_categories jc
    WHERE jc.is_active = true 
      AND LOWER(jc.name) ILIKE '%' || LOWER(search_term) || '%'
    ORDER BY jc.name
    LIMIT 3;
  END IF;
END;
$$;

-- Function to save conversation state
CREATE OR REPLACE FUNCTION save_conversation_state(
  p_session_id TEXT,
  p_user_id UUID,
  p_step TEXT,
  p_data JSONB,
  p_job_category_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  session_uuid UUID;
BEGIN
  INSERT INTO ai_conversation_sessions 
    (user_id, session_id, current_step, collected_data, job_category_id, updated_at)
  VALUES 
    (p_user_id, p_session_id, p_step, p_data, p_job_category_id, NOW())
  ON CONFLICT (session_id)
  DO UPDATE SET
    current_step = EXCLUDED.current_step,
    collected_data = EXCLUDED.collected_data,
    job_category_id = EXCLUDED.job_category_id,
    updated_at = NOW()
  RETURNING id INTO session_uuid;
  
  RETURN session_uuid;
END;
$$;

-- Function to create/update job request draft
CREATE OR REPLACE FUNCTION save_job_request_draft(
  p_session_id TEXT,
  p_user_id UUID,
  p_draft_data JSONB
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  draft_uuid UUID;
  job_category_uuid UUID;
BEGIN
  -- Get job category ID from draft data
  IF p_draft_data->>'job_category_id' IS NOT NULL THEN
    job_category_uuid := (p_draft_data->>'job_category_id')::UUID;
  END IF;
  
  INSERT INTO ai_job_request_drafts 
    (user_id, session_id, job_category_id, title, description, 
     location_address, preferred_date, preferred_time, estimated_duration,
     hourly_rate, special_requirements, updated_at)
  VALUES 
    (p_user_id, p_session_id, job_category_uuid, 
     p_draft_data->>'title',
     p_draft_data->>'description',
     p_draft_data->>'location_address',
     (p_draft_data->>'preferred_date')::DATE,
     (p_draft_data->>'preferred_time')::TIME,
     (p_draft_data->>'estimated_duration')::INTEGER,
     (p_draft_data->>'hourly_rate')::DECIMAL,
     COALESCE(p_draft_data->'special_requirements', '{}'::jsonb),
     NOW())
  ON CONFLICT (session_id)
  DO UPDATE SET
    job_category_id = EXCLUDED.job_category_id,
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    location_address = EXCLUDED.location_address,
    preferred_date = EXCLUDED.preferred_date,
    preferred_time = EXCLUDED.preferred_time,
    estimated_duration = EXCLUDED.estimated_duration,
    hourly_rate = EXCLUDED.hourly_rate,
    special_requirements = EXCLUDED.special_requirements,
    updated_at = NOW()
  RETURNING id INTO draft_uuid;
  
  RETURN draft_uuid;
END;
$$;

-- Function to generate AI job title
CREATE OR REPLACE FUNCTION generate_job_title(
  p_category_name TEXT,
  p_description TEXT,
  p_location TEXT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  title_parts TEXT[];
  final_title TEXT;
BEGIN
  -- Start with category name
  title_parts := ARRAY[INITCAP(p_category_name) || ' Needed'];
  
  -- Add key description elements
  IF p_description IS NOT NULL AND LENGTH(p_description) > 0 THEN
    -- Extract key terms (this is a simple implementation)
    IF p_description ILIKE '%urgent%' OR p_description ILIKE '%asap%' THEN
      title_parts := title_parts || ARRAY['- Urgent'];
    END IF;
    
    IF p_description ILIKE '%experienced%' OR p_description ILIKE '%professional%' THEN
      title_parts := title_parts || ARRAY['- Experienced'];
    END IF;
  END IF;
  
  -- Add location if provided
  IF p_location IS NOT NULL AND LENGTH(p_location) > 0 THEN
    title_parts := title_parts || ARRAY['in ' || p_location];
  END IF;
  
  -- Combine parts
  final_title := array_to_string(title_parts, ' ');
  
  -- Ensure reasonable length (max 100 characters)
  IF LENGTH(final_title) > 100 THEN
    final_title := LEFT(final_title, 97) || '...';
  END IF;
  
  RETURN final_title;
END;
$$;

-- Create triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ai_conversation_sessions_updated_at
  BEFORE UPDATE ON ai_conversation_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_job_request_drafts_updated_at
  BEFORE UPDATE ON ai_job_request_drafts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_unknown_job_requests_updated_at
  BEFORE UPDATE ON ai_unknown_job_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_job_aliases_updated_at
  BEFORE UPDATE ON ai_job_aliases
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON ai_conversation_sessions TO anon;
GRANT SELECT, INSERT, UPDATE ON ai_job_request_drafts TO anon;
GRANT SELECT, INSERT ON ai_unknown_job_requests TO anon;
GRANT SELECT ON ai_job_aliases TO anon;

GRANT ALL ON ai_conversation_sessions TO authenticated;
GRANT ALL ON ai_job_request_drafts TO authenticated;
GRANT ALL ON ai_unknown_job_requests TO authenticated;
GRANT ALL ON ai_job_aliases TO authenticated;

-- Grant function permissions
GRANT EXECUTE ON FUNCTION find_matching_job_categories(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION save_conversation_state(TEXT, UUID, TEXT, JSONB, UUID) TO anon;
GRANT EXECUTE ON FUNCTION save_job_request_draft(TEXT, UUID, JSONB) TO anon;
GRANT EXECUTE ON FUNCTION generate_job_title(TEXT, TEXT, TEXT) TO anon;

GRANT EXECUTE ON FUNCTION find_matching_job_categories(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION save_conversation_state(TEXT, UUID, TEXT, JSONB, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION save_job_request_draft(TEXT, UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_job_title(TEXT, TEXT, TEXT) TO authenticated; 