-- Fix payment confirmation database errors
-- Add missing columns to payment_confirmations and jobs tables

-- Add updated_at column to payment_confirmations table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payment_confirmations' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE payment_confirmations 
        ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        
        -- Update existing records to have current timestamp
        UPDATE payment_confirmations 
        SET updated_at = created_at 
        WHERE updated_at IS NULL;
    END IF;
END $$;

-- Add payment_notes column to jobs table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'payment_notes'
    ) THEN
        ALTER TABLE jobs 
        ADD COLUMN payment_notes TEXT;
    END IF;
END $$;

-- Create trigger to automatically update updated_at timestamp
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'update_payment_confirmations_updated_at'
    ) THEN
        -- Create trigger function if it doesn't exist
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS '
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        ' LANGUAGE plpgsql;

        -- Create trigger
        CREATE TRIGGER update_payment_confirmations_updated_at
            BEFORE UPDATE ON payment_confirmations
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$; 