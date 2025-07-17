-- Migration: 070_gemini_ai_enhancements.sql
-- Description: Gemini AI-specific optimizations for natural language conversation flow
-- Created: 2024-12-20
-- Enhances: 068_enhanced_ai_chatbot_system.sql

-- Add AI-specific fields to conversation sessions
ALTER TABLE ai_conversation_sessions 
ADD COLUMN IF NOT EXISTS conversation_history JSONB DEFAULT '[]',
ADD COLUMN IF NOT EXISTS completion_percentage INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS missing_fields TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS last_ai_response TEXT,
ADD COLUMN IF NOT EXISTS conversation_phase TEXT DEFAULT 'greeting';

-- Add AI-specific fields to job request drafts
ALTER TABLE ai_job_request_drafts
ADD COLUMN IF NOT EXISTS extraction_confidence FLOAT DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS ai_generated_summary TEXT,
ADD COLUMN IF NOT EXISTS conversation_context JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS form_completion_status TEXT DEFAULT 'incomplete';

-- Create conversation messages table for detailed chat history
CREATE TABLE IF NOT EXISTS ai_conversation_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id TEXT NOT NULL REFERENCES ai_conversation_sessions(session_id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'button', 'form_data', 'navigation')),
  metadata JSONB DEFAULT '{}',
  tokens_used INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better AI performance
CREATE INDEX IF NOT EXISTS idx_ai_conversation_messages_session ON ai_conversation_messages(session_id, created_at);
CREATE INDEX IF NOT EXISTS idx_ai_conversation_messages_role ON ai_conversation_messages(role, session_id);
CREATE INDEX IF NOT EXISTS idx_ai_conversation_sessions_phase ON ai_conversation_sessions(conversation_phase, is_active);
CREATE INDEX IF NOT EXISTS idx_ai_conversation_sessions_completion ON ai_conversation_sessions(completion_percentage, is_active);

-- Add RLS policies for conversation messages
ALTER TABLE ai_conversation_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own conversation messages" ON ai_conversation_messages
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM ai_conversation_sessions 
      WHERE session_id = ai_conversation_messages.session_id 
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Anonymous users can create conversation messages" ON ai_conversation_messages
  FOR INSERT WITH CHECK (true);

-- Enhanced function to save conversation with AI message history
CREATE OR REPLACE FUNCTION save_openai_conversation(
  p_session_id TEXT,
  p_user_id UUID,
  p_user_message TEXT,
  p_ai_response TEXT,
  p_extracted_data JSONB DEFAULT '{}',
  p_conversation_phase TEXT DEFAULT 'chatting',
  p_completion_percentage INTEGER DEFAULT 0
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  session_uuid UUID;
  missing_fields TEXT[] := '{}';
  conversation_hist JSONB;
BEGIN
  -- Calculate missing fields based on extracted data
  IF p_extracted_data->>'job_category_id' IS NULL THEN
    missing_fields := missing_fields || ARRAY['job_category'];
  END IF;
  
  IF p_extracted_data->>'preferred_date' IS NULL THEN
    missing_fields := missing_fields || ARRAY['date'];
  END IF;
  
  IF p_extracted_data->>'preferred_time' IS NULL THEN
    missing_fields := missing_fields || ARRAY['time'];
  END IF;
  
  IF p_extracted_data->>'location_address' IS NULL THEN
    missing_fields := missing_fields || ARRAY['location'];
  END IF;
  
  IF p_extracted_data->>'description' IS NULL THEN
    missing_fields := missing_fields || ARRAY['description'];
  END IF;

  -- Update conversation session
  INSERT INTO ai_conversation_sessions 
    (user_id, session_id, current_step, collected_data, conversation_phase, 
     completion_percentage, missing_fields, last_ai_response, updated_at)
  VALUES 
    (p_user_id, p_session_id, p_conversation_phase, p_extracted_data, p_conversation_phase,
     p_completion_percentage, missing_fields, p_ai_response, NOW())
  ON CONFLICT (session_id)
  DO UPDATE SET
    current_step = EXCLUDED.current_step,
    collected_data = EXCLUDED.collected_data,
    conversation_phase = EXCLUDED.conversation_phase,
    completion_percentage = EXCLUDED.completion_percentage,
    missing_fields = EXCLUDED.missing_fields,
    last_ai_response = EXCLUDED.last_ai_response,
    updated_at = NOW()
  RETURNING id INTO session_uuid;

  -- Save user message
  INSERT INTO ai_conversation_messages (session_id, role, content, message_type)
  VALUES (p_session_id, 'user', p_user_message, 'text');

  -- Save AI response
  INSERT INTO ai_conversation_messages (session_id, role, content, message_type)
  VALUES (p_session_id, 'assistant', p_ai_response, 'text');

  RETURN session_uuid;
END;
$$;

-- Enhanced function to get conversation history for AI context
CREATE OR REPLACE FUNCTION get_conversation_history(
  p_session_id TEXT,
  p_limit INTEGER DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  messages JSONB;
  session_data JSONB;
  result JSONB;
BEGIN
  -- Get recent messages
  SELECT jsonb_agg(
    jsonb_build_object(
      'role', role,
      'content', content,
      'timestamp', created_at
    ) ORDER BY created_at ASC
  )
  INTO messages
  FROM (
    SELECT role, content, created_at 
    FROM ai_conversation_messages 
    WHERE session_id = p_session_id
    ORDER BY created_at DESC
    LIMIT p_limit
  ) recent_messages;

  -- Get session data
  SELECT jsonb_build_object(
    'collected_data', collected_data,
    'conversation_phase', conversation_phase,
    'completion_percentage', completion_percentage,
    'missing_fields', missing_fields,
    'job_category_id', job_category_id
  )
  INTO session_data
  FROM ai_conversation_sessions
  WHERE session_id = p_session_id;

  -- Combine into result
  result := jsonb_build_object(
    'messages', COALESCE(messages, '[]'::jsonb),
    'session_data', COALESCE(session_data, '{}'::jsonb)
  );

  RETURN result;
END;
$$;

-- Function to calculate conversation completion percentage
CREATE OR REPLACE FUNCTION calculate_completion_percentage(
  p_extracted_data JSONB
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  total_fields INTEGER := 6; -- job_category, date, time, location, description, title
  completed_fields INTEGER := 0;
BEGIN
  IF p_extracted_data->>'job_category_id' IS NOT NULL THEN
    completed_fields := completed_fields + 1;
  END IF;
  
  IF p_extracted_data->>'preferred_date' IS NOT NULL THEN
    completed_fields := completed_fields + 1;
  END IF;
  
  IF p_extracted_data->>'preferred_time' IS NOT NULL THEN
    completed_fields := completed_fields + 1;
  END IF;
  
  IF p_extracted_data->>'location_address' IS NOT NULL THEN
    completed_fields := completed_fields + 1;
  END IF;
  
  IF p_extracted_data->>'description' IS NOT NULL THEN
    completed_fields := completed_fields + 1;
  END IF;
  
  IF p_extracted_data->>'title' IS NOT NULL THEN
    completed_fields := completed_fields + 1;
  END IF;

  RETURN ROUND((completed_fields::FLOAT / total_fields::FLOAT) * 100);
END;
$$;

-- Function to generate next question based on missing fields
CREATE OR REPLACE FUNCTION generate_next_question_prompt(
  p_session_id TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  session_data RECORD;
  next_question TEXT;
BEGIN
  SELECT 
    missing_fields,
    collected_data,
    conversation_phase,
    completion_percentage
  INTO session_data
  FROM ai_conversation_sessions
  WHERE session_id = p_session_id;

  IF session_data.missing_fields IS NULL OR array_length(session_data.missing_fields, 1) = 0 THEN
    RETURN 'conversation_complete';
  END IF;

  -- Prioritize questions based on conversation flow
  IF 'job_category' = ANY(session_data.missing_fields) THEN
    RETURN 'ask_job_category';
  ELSIF 'date' = ANY(session_data.missing_fields) THEN
    RETURN 'ask_date';
  ELSIF 'time' = ANY(session_data.missing_fields) THEN
    RETURN 'ask_time';
  ELSIF 'location' = ANY(session_data.missing_fields) THEN
    RETURN 'ask_location';
  ELSIF 'description' = ANY(session_data.missing_fields) THEN
    RETURN 'ask_description';
  ELSE
    RETURN 'conversation_complete';
  END IF;
END;
$$;

-- Enhanced job draft saving with AI confidence scoring
CREATE OR REPLACE FUNCTION save_openai_job_draft(
  p_session_id TEXT,
  p_user_id UUID,
  p_draft_data JSONB,
  p_confidence FLOAT DEFAULT 0.8,
  p_ai_summary TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  draft_uuid UUID;
  job_category_uuid UUID;
  completion_status TEXT;
  completion_pct INTEGER;
BEGIN
  -- Get job category ID from draft data
  IF p_draft_data->>'job_category_id' IS NOT NULL THEN
    job_category_uuid := (p_draft_data->>'job_category_id')::UUID;
  END IF;

  -- Calculate completion status
  completion_pct := calculate_completion_percentage(p_draft_data);
  
  IF completion_pct >= 100 THEN
    completion_status := 'complete';
  ELSIF completion_pct >= 80 THEN
    completion_status := 'nearly_complete';
  ELSIF completion_pct >= 50 THEN
    completion_status := 'in_progress';
  ELSE
    completion_status := 'incomplete';
  END IF;
  
  INSERT INTO ai_job_request_drafts 
    (user_id, session_id, job_category_id, title, description, 
     location_address, preferred_date, preferred_time, estimated_duration,
     hourly_rate, special_requirements, extraction_confidence, 
     ai_generated_summary, form_completion_status, updated_at)
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
     p_confidence,
     p_ai_summary,
     completion_status,
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
    extraction_confidence = EXCLUDED.extraction_confidence,
    ai_generated_summary = EXCLUDED.ai_generated_summary,
    form_completion_status = EXCLUDED.form_completion_status,
    updated_at = NOW()
  RETURNING id INTO draft_uuid;
  
  RETURN draft_uuid;
END;
$$;

-- Grant permissions for new functions and tables
GRANT SELECT, INSERT, UPDATE ON ai_conversation_messages TO anon;
GRANT ALL ON ai_conversation_messages TO authenticated;

GRANT EXECUTE ON FUNCTION save_openai_conversation(TEXT, UUID, TEXT, TEXT, JSONB, TEXT, INTEGER) TO anon;
GRANT EXECUTE ON FUNCTION get_conversation_history(TEXT, INTEGER) TO anon;
GRANT EXECUTE ON FUNCTION calculate_completion_percentage(JSONB) TO anon;
GRANT EXECUTE ON FUNCTION generate_next_question_prompt(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION save_openai_job_draft(TEXT, UUID, JSONB, FLOAT, TEXT) TO anon;

GRANT EXECUTE ON FUNCTION save_openai_conversation(TEXT, UUID, TEXT, TEXT, JSONB, TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_conversation_history(TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_completion_percentage(JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION generate_next_question_prompt(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION save_openai_job_draft(TEXT, UUID, JSONB, FLOAT, TEXT) TO authenticated;

-- Add trigger for conversation messages
CREATE TRIGGER update_ai_conversation_messages_updated_at
  BEFORE UPDATE ON ai_conversation_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create cleanup function for old conversations (optional)
CREATE OR REPLACE FUNCTION cleanup_old_conversations()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  -- Delete conversations older than 30 days that are inactive
  DELETE FROM ai_conversation_sessions 
  WHERE created_at < NOW() - INTERVAL '30 days' 
    AND is_active = false;
    
  -- Delete messages for non-existent sessions
  DELETE FROM ai_conversation_messages 
  WHERE session_id NOT IN (
    SELECT session_id FROM ai_conversation_sessions
  );
END;
$$;

GRANT EXECUTE ON FUNCTION cleanup_old_conversations() TO authenticated; 