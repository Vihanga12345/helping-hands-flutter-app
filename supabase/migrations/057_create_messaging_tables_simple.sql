-- Migration 057: Create messaging and calling tables (simplified)
-- Created: 2024-01-XX
-- Purpose: Create messaging tables from scratch with proper error handling

-- Drop existing tables if they exist (to start fresh)
DROP TABLE IF EXISTS call_logs CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;

-- Create conversations table
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    helper_id UUID REFERENCES users(id) ON DELETE CASCADE,
    helpee_id UUID REFERENCES users(id) ON DELETE CASCADE,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    helper_unread_count INTEGER DEFAULT 0,
    helpee_unread_count INTEGER DEFAULT 0
);

-- Create messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    message_text TEXT,
    message_type VARCHAR(50) DEFAULT 'text',
    attachment_url TEXT,
    attachment_type VARCHAR(50),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create call_logs table
CREATE TABLE call_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    caller_id UUID REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES users(id) ON DELETE CASCADE,
    call_type VARCHAR(20) DEFAULT 'audio',
    call_status VARCHAR(20) DEFAULT 'initiated',
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER DEFAULT 0,
    webrtc_session_id TEXT
);

-- Create indexes
CREATE INDEX idx_conversations_job_id ON conversations(job_id);
CREATE INDEX idx_conversations_helper_id ON conversations(helper_id);
CREATE INDEX idx_conversations_helpee_id ON conversations(helpee_id);
CREATE INDEX idx_conversations_last_message_at ON conversations(last_message_at DESC);

CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX idx_messages_is_read ON messages(is_read);

CREATE INDEX idx_call_logs_conversation_id ON call_logs(conversation_id);
CREATE INDEX idx_call_logs_caller_id ON call_logs(caller_id);
CREATE INDEX idx_call_logs_receiver_id ON call_logs(receiver_id);
CREATE INDEX idx_call_logs_start_time ON call_logs(start_time DESC);

-- Add triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create database functions
CREATE OR REPLACE FUNCTION get_or_create_conversation(
    p_job_id UUID,
    p_helper_id UUID,
    p_helpee_id UUID
)
RETURNS UUID AS $$
DECLARE
    conversation_id UUID;
BEGIN
    -- Try to find existing conversation
    SELECT id INTO conversation_id
    FROM conversations
    WHERE job_id = p_job_id 
        AND helper_id = p_helper_id 
        AND helpee_id = p_helpee_id;
    
    -- If not found, create new conversation
    IF conversation_id IS NULL THEN
        INSERT INTO conversations (job_id, helper_id, helpee_id)
        VALUES (p_job_id, p_helper_id, p_helpee_id)
        RETURNING id INTO conversation_id;
    END IF;
    
    RETURN conversation_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION send_message(
    p_conversation_id UUID,
    p_sender_id UUID,
    p_message_text TEXT,
    p_message_type VARCHAR DEFAULT 'text',
    p_attachment_url TEXT DEFAULT NULL,
    p_attachment_type VARCHAR DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    message_id UUID;
    sender_role VARCHAR;
BEGIN
    -- Insert the message
    INSERT INTO messages (
        conversation_id, 
        sender_id, 
        message_text, 
        message_type, 
        attachment_url, 
        attachment_type
    )
    VALUES (
        p_conversation_id, 
        p_sender_id, 
        p_message_text, 
        p_message_type, 
        p_attachment_url, 
        p_attachment_type
    )
    RETURNING id INTO message_id;
    
    -- Update conversation last_message_at
    UPDATE conversations 
    SET last_message_at = NOW()
    WHERE id = p_conversation_id;
    
    -- Update unread counts
    SELECT user_type INTO sender_role 
    FROM users 
    WHERE id = p_sender_id;
    
    IF sender_role = 'helper' THEN
        UPDATE conversations 
        SET helpee_unread_count = helpee_unread_count + 1
        WHERE id = p_conversation_id;
    ELSE
        UPDATE conversations 
        SET helper_unread_count = helper_unread_count + 1
        WHERE id = p_conversation_id;
    END IF;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mark_messages_as_read(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER;
    user_role VARCHAR;
BEGIN
    -- Mark messages as read
    UPDATE messages 
    SET is_read = true 
    WHERE conversation_id = p_conversation_id 
        AND sender_id != p_user_id 
        AND is_read = false;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    -- Reset unread count
    SELECT user_type INTO user_role 
    FROM users 
    WHERE id = p_user_id;
    
    IF user_role = 'helper' THEN
        UPDATE conversations 
        SET helper_unread_count = 0
        WHERE id = p_conversation_id;
    ELSE
        UPDATE conversations 
        SET helpee_unread_count = 0
        WHERE id = p_conversation_id;
    END IF;
    
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION log_call(
    p_conversation_id UUID,
    p_caller_id UUID,
    p_receiver_id UUID,
    p_call_type VARCHAR DEFAULT 'audio',
    p_webrtc_session_id TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    call_log_id UUID;
BEGIN
    INSERT INTO call_logs (
        conversation_id,
        caller_id,
        receiver_id,
        call_type,
        webrtc_session_id
    )
    VALUES (
        p_conversation_id,
        p_caller_id,
        p_receiver_id,
        p_call_type,
        p_webrtc_session_id
    )
    RETURNING id INTO call_log_id;
    
    RETURN call_log_id;
END;
$$ LANGUAGE plpgsql;

-- Enable Row Level Security
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "conversations_select_policy" ON conversations
    FOR SELECT USING (helper_id = auth.uid() OR helpee_id = auth.uid());

CREATE POLICY "conversations_insert_policy" ON conversations
    FOR INSERT WITH CHECK (helper_id = auth.uid() OR helpee_id = auth.uid());

CREATE POLICY "conversations_update_policy" ON conversations
    FOR UPDATE USING (helper_id = auth.uid() OR helpee_id = auth.uid());

CREATE POLICY "messages_select_policy" ON messages
    FOR SELECT USING (
        conversation_id IN (
            SELECT id FROM conversations 
            WHERE helper_id = auth.uid() OR helpee_id = auth.uid()
        )
    );

CREATE POLICY "messages_insert_policy" ON messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid() AND
        conversation_id IN (
            SELECT id FROM conversations 
            WHERE helper_id = auth.uid() OR helpee_id = auth.uid()
        )
    );

CREATE POLICY "messages_update_policy" ON messages
    FOR UPDATE USING (
        conversation_id IN (
            SELECT id FROM conversations 
            WHERE helper_id = auth.uid() OR helpee_id = auth.uid()
        )
    );

CREATE POLICY "call_logs_select_policy" ON call_logs
    FOR SELECT USING (caller_id = auth.uid() OR receiver_id = auth.uid());

CREATE POLICY "call_logs_insert_policy" ON call_logs
    FOR INSERT WITH CHECK (caller_id = auth.uid() OR receiver_id = auth.uid());

CREATE POLICY "call_logs_update_policy" ON call_logs
    FOR UPDATE USING (caller_id = auth.uid() OR receiver_id = auth.uid());

-- Grant permissions
GRANT ALL ON conversations TO authenticated;
GRANT ALL ON messages TO authenticated;
GRANT ALL ON call_logs TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated; 