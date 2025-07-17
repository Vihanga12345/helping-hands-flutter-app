-- Fix foreign key constraint for seen_by_admin_id in reports table
-- Remove the foreign key constraint since admins are not stored in users table

-- Drop the foreign key constraint
ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_seen_by_admin_id_fkey;

-- Make seen_by_admin_id column nullable and allow any UUID
ALTER TABLE reports ALTER COLUMN seen_by_admin_id DROP NOT NULL;

-- Add a comment to clarify that this field can contain admin IDs that are not in users table
COMMENT ON COLUMN reports.seen_by_admin_id IS 'Admin ID who marked the report as seen. May not reference users table as admins have separate authentication.'; 