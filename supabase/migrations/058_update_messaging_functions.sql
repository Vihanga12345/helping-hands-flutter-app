-- Migration 058: Update messaging functions to handle null job IDs
-- Created: 2024-01-XX
-- Purpose: Allow conversations without specific job context (general conversations)

-- Update the get_or_create_conversation function to handle null job_id
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
    -- If job_id is null, look for general conversation between users
    IF p_job_id IS NULL OR p_job_id = '00000000-0000-0000-0000-000000000000'::UUID THEN
        SELECT id INTO conversation_id
        FROM conversations
        WHERE (job_id IS NULL OR job_id = '00000000-0000-0000-0000-000000000000'::UUID)
            AND helper_id = p_helper_id 
            AND helpee_id = p_helpee_id;
    ELSE
        SELECT id INTO conversation_id
        FROM conversations
        WHERE job_id = p_job_id 
            AND helper_id = p_helper_id 
            AND helpee_id = p_helpee_id;
    END IF;
    
    -- If not found, create new conversation
    IF conversation_id IS NULL THEN
        INSERT INTO conversations (
            job_id, 
            helper_id, 
            helpee_id
        )
        VALUES (
            CASE 
                WHEN p_job_id = '00000000-0000-0000-0000-000000000000'::UUID THEN NULL
                ELSE p_job_id
            END,
            p_helper_id, 
            p_helpee_id
        )
        RETURNING id INTO conversation_id;
    END IF;
    
    RETURN conversation_id;
END;
$$ LANGUAGE plpgsql;

-- Update conversations table to allow NULL job_id
ALTER TABLE conversations ALTER COLUMN job_id DROP NOT NULL;

-- Update the foreign key constraint to handle NULL values
ALTER TABLE conversations DROP CONSTRAINT IF EXISTS conversations_job_id_fkey;
ALTER TABLE conversations ADD CONSTRAINT conversations_job_id_fkey 
    FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;

-- Update RLS policies to handle conversations without job context
DROP POLICY IF EXISTS "conversations_select_policy" ON conversations;
CREATE POLICY "conversations_select_policy" ON conversations
    FOR SELECT USING (
        helper_id = auth.uid() OR 
        helpee_id = auth.uid()
    );

DROP POLICY IF EXISTS "conversations_insert_policy" ON conversations;
CREATE POLICY "conversations_insert_policy" ON conversations
    FOR INSERT WITH CHECK (
        helper_id = auth.uid() OR 
        helpee_id = auth.uid()
    );

DROP POLICY IF EXISTS "conversations_update_policy" ON conversations;
CREATE POLICY "conversations_update_policy" ON conversations
    FOR UPDATE USING (
        helper_id = auth.uid() OR 
        helpee_id = auth.uid()
    ); 