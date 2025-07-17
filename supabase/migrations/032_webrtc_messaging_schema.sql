-- Create conversations table
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    helpee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    helper_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(job_id) -- A job can only have one conversation
);

-- Create messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_text TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text', -- 'text', 'image', 'call_log'
    is_read BOOLEAN DEFAULT false,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create call logs table
CREATE TABLE call_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    caller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    call_duration INTEGER DEFAULT 0, -- in seconds
    call_status VARCHAR(20), -- 'completed', 'missed', 'declined'
    call_type VARCHAR(20) DEFAULT 'webrtc',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_logs ENABLE ROW LEVEL SECURITY;

-- Policies for conversations
CREATE POLICY "Users can view their own conversations"
ON conversations FOR SELECT
USING (auth.uid() IN (helpee_id, helper_id));

CREATE POLICY "Users can create conversations for their jobs"
ON conversations FOR INSERT
WITH CHECK (auth.uid() IN (helpee_id, helper_id));

-- Policies for messages
CREATE POLICY "Users can view messages in their conversations"
ON messages FOR SELECT
USING (
  (SELECT auth.uid() FROM conversations c WHERE c.id = conversation_id) = auth.uid()
);

CREATE POLICY "Users can send messages in their conversations"
ON messages FOR INSERT
WITH CHECK (
  (SELECT auth.uid() FROM conversations c WHERE c.id = conversation_id) = sender_id
);

-- Policies for call_logs
CREATE POLICY "Users can view their own call logs"
ON call_logs FOR SELECT
USING (auth.uid() IN (caller_id, receiver_id));

CREATE POLICY "Users can create call logs for their jobs"
ON call_logs FOR INSERT
WITH CHECK (auth.uid() IN (caller_id, receiver_id)); 