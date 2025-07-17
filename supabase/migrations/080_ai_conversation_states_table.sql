-- ============================================================================
-- Migration 080: AI Conversation States Table
-- Date: January 2025
-- Purpose: Create table to store sequential AI conversation states for improved bot
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create AI conversation states table
CREATE TABLE IF NOT EXISTS ai_conversation_states (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id VARCHAR(255) UNIQUE NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    current_step VARCHAR(50) NOT NULL DEFAULT 'jobCategory',
    collected_data JSONB DEFAULT '{}',
    job_categories JSONB DEFAULT '[]',
    job_questions JSONB DEFAULT '[]',
    asked_questions JSONB DEFAULT '[]',
    last_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_ai_conversation_states_conversation_id 
    ON ai_conversation_states(conversation_id);
    
CREATE INDEX IF NOT EXISTS idx_ai_conversation_states_user_id 
    ON ai_conversation_states(user_id);
    
CREATE INDEX IF NOT EXISTS idx_ai_conversation_states_updated_at 
    ON ai_conversation_states(updated_at);

-- Create function to auto-update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_ai_conversation_state_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update timestamp
DROP TRIGGER IF EXISTS trigger_update_ai_conversation_state_timestamp ON ai_conversation_states;
CREATE TRIGGER trigger_update_ai_conversation_state_timestamp
    BEFORE UPDATE ON ai_conversation_states
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_conversation_state_timestamp();

-- Add comments for documentation
COMMENT ON TABLE ai_conversation_states IS 'Stores sequential conversation states for AI chatbot';
COMMENT ON COLUMN ai_conversation_states.conversation_id IS 'Unique identifier for each conversation session';
COMMENT ON COLUMN ai_conversation_states.current_step IS 'Current step in the conversation flow (jobCategory, jobQuestions, preferredDate, etc.)';
COMMENT ON COLUMN ai_conversation_states.collected_data IS 'Progressive job form data collected during conversation';
COMMENT ON COLUMN ai_conversation_states.job_categories IS 'Available job categories for this conversation';
COMMENT ON COLUMN ai_conversation_states.job_questions IS 'Job-specific questions for selected category';
COMMENT ON COLUMN ai_conversation_states.asked_questions IS 'Array of question IDs that have been asked to avoid repetition';

-- Grant necessary permissions (adjust as needed for your setup)
-- These permissions may need to be adjusted based on your RLS policies
GRANT ALL ON ai_conversation_states TO authenticated;
GRANT ALL ON ai_conversation_states TO anon; 