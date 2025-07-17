-- Migration 056: Fix messaging table columns
-- Created: 2024-01-XX
-- Purpose: Add missing columns to existing messaging tables

-- Add missing columns to conversations table if they don't exist
DO $$ 
BEGIN
    -- Add created_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='conversations' AND column_name='created_at') THEN
        ALTER TABLE conversations ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='conversations' AND column_name='updated_at') THEN
        ALTER TABLE conversations ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Add is_active column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='conversations' AND column_name='is_active') THEN
        ALTER TABLE conversations ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
    
    -- Add helper_unread_count column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='conversations' AND column_name='helper_unread_count') THEN
        ALTER TABLE conversations ADD COLUMN helper_unread_count INTEGER DEFAULT 0;
    END IF;
    
    -- Add helpee_unread_count column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='conversations' AND column_name='helpee_unread_count') THEN
        ALTER TABLE conversations ADD COLUMN helpee_unread_count INTEGER DEFAULT 0;
    END IF;
    
    -- Add last_message_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='conversations' AND column_name='last_message_at') THEN
        ALTER TABLE conversations ADD COLUMN last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Add missing columns to messages table if they don't exist
DO $$ 
BEGIN
    -- Add created_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='created_at') THEN
        ALTER TABLE messages ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='updated_at') THEN
        ALTER TABLE messages ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Add message_type column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='message_type') THEN
        ALTER TABLE messages ADD COLUMN message_type VARCHAR(50) DEFAULT 'text';
    END IF;
    
    -- Add attachment_url column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='attachment_url') THEN
        ALTER TABLE messages ADD COLUMN attachment_url TEXT;
    END IF;
    
    -- Add attachment_type column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='attachment_type') THEN
        ALTER TABLE messages ADD COLUMN attachment_type VARCHAR(50);
    END IF;
    
    -- Add is_read column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='is_read') THEN
        ALTER TABLE messages ADD COLUMN is_read BOOLEAN DEFAULT false;
    END IF;
END $$;

-- Add missing columns to call_logs table if they don't exist
DO $$ 
BEGIN
    -- Add call_type column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='call_logs' AND column_name='call_type') THEN
        ALTER TABLE call_logs ADD COLUMN call_type VARCHAR(20) DEFAULT 'audio';
    END IF;
    
    -- Add call_status column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='call_logs' AND column_name='call_status') THEN
        ALTER TABLE call_logs ADD COLUMN call_status VARCHAR(20) DEFAULT 'initiated';
    END IF;
    
    -- Add start_time column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='call_logs' AND column_name='start_time') THEN
        ALTER TABLE call_logs ADD COLUMN start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Add end_time column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='call_logs' AND column_name='end_time') THEN
        ALTER TABLE call_logs ADD COLUMN end_time TIMESTAMP WITH TIME ZONE;
    END IF;
    
    -- Add duration_seconds column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='call_logs' AND column_name='duration_seconds') THEN
        ALTER TABLE call_logs ADD COLUMN duration_seconds INTEGER DEFAULT 0;
    END IF;
    
    -- Add webrtc_session_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='call_logs' AND column_name='webrtc_session_id') THEN
        ALTER TABLE call_logs ADD COLUMN webrtc_session_id TEXT;
    END IF;
END $$;

-- Create missing foreign key constraints if they don't exist
DO $$ 
BEGIN
    -- Add foreign key constraint for conversations.job_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='conversations_job_id_fkey' AND table_name='conversations') THEN
        ALTER TABLE conversations ADD CONSTRAINT conversations_job_id_fkey 
        FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;
    END IF;
    
    -- Add foreign key constraint for conversations.helper_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='conversations_helper_id_fkey' AND table_name='conversations') THEN
        ALTER TABLE conversations ADD CONSTRAINT conversations_helper_id_fkey 
        FOREIGN KEY (helper_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    
    -- Add foreign key constraint for conversations.helpee_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='conversations_helpee_id_fkey' AND table_name='conversations') THEN
        ALTER TABLE conversations ADD CONSTRAINT conversations_helpee_id_fkey 
        FOREIGN KEY (helpee_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    
    -- Add foreign key constraint for messages.conversation_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='messages_conversation_id_fkey' AND table_name='messages') THEN
        ALTER TABLE messages ADD CONSTRAINT messages_conversation_id_fkey 
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;
    END IF;
    
    -- Add foreign key constraint for messages.sender_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='messages_sender_id_fkey' AND table_name='messages') THEN
        ALTER TABLE messages ADD CONSTRAINT messages_sender_id_fkey 
        FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    
    -- Add foreign key constraint for call_logs.conversation_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='call_logs_conversation_id_fkey' AND table_name='call_logs') THEN
        ALTER TABLE call_logs ADD CONSTRAINT call_logs_conversation_id_fkey 
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;
    END IF;
    
    -- Add foreign key constraint for call_logs.caller_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='call_logs_caller_id_fkey' AND table_name='call_logs') THEN
        ALTER TABLE call_logs ADD CONSTRAINT call_logs_caller_id_fkey 
        FOREIGN KEY (caller_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    
    -- Add foreign key constraint for call_logs.receiver_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name='call_logs_receiver_id_fkey' AND table_name='call_logs') THEN
        ALTER TABLE call_logs ADD CONSTRAINT call_logs_receiver_id_fkey 
        FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Update existing records to have proper timestamps if they're null
UPDATE conversations SET created_at = NOW() WHERE created_at IS NULL;
UPDATE conversations SET updated_at = NOW() WHERE updated_at IS NULL;
UPDATE conversations SET last_message_at = NOW() WHERE last_message_at IS NULL;
UPDATE messages SET created_at = NOW() WHERE created_at IS NULL;
UPDATE messages SET updated_at = NOW() WHERE updated_at IS NULL; 