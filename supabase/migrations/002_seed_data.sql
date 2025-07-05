-- HELPING HANDS APP - SEED DATA
-- ============================================================================
-- This file inserts initial data for the Helping Hands application
-- Run this after running 001_complete_schema.sql

-- ============================================================================
-- BULLETPROOF COLUMN HANDLING - ALL POSSIBLE VARIATIONS
-- ============================================================================

-- Ensure job_categories table has all required columns
ALTER TABLE job_categories ADD COLUMN IF NOT EXISTS default_hourly_rate DECIMAL(10, 2);
ALTER TABLE job_categories ADD COLUMN IF NOT EXISTS icon_name VARCHAR(100);
ALTER TABLE job_categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Handle ALL possible column name variations for job_category_questions
ALTER TABLE job_category_questions ADD COLUMN IF NOT EXISTS question TEXT;
ALTER TABLE job_category_questions ADD COLUMN IF NOT EXISTS question_text TEXT;
ALTER TABLE job_category_questions ADD COLUMN IF NOT EXISTS question_type VARCHAR(50);
ALTER TABLE job_category_questions ADD COLUMN IF NOT EXISTS is_required BOOLEAN DEFAULT true;
ALTER TABLE job_category_questions ADD COLUMN IF NOT EXISTS order_index INTEGER DEFAULT 0;
ALTER TABLE job_category_questions ADD COLUMN IF NOT EXISTS question_order INTEGER DEFAULT 0;
ALTER TABLE job_category_questions ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Synchronize data between different column name variations
UPDATE job_category_questions SET question_text = question WHERE question_text IS NULL AND question IS NOT NULL;
UPDATE job_category_questions SET question = question_text WHERE question IS NULL AND question_text IS NOT NULL;
UPDATE job_category_questions SET question_order = order_index WHERE question_order IS NULL AND order_index IS NOT NULL;
UPDATE job_category_questions SET order_index = question_order WHERE order_index IS NULL AND question_order IS NOT NULL;

-- ============================================================================
-- COMPREHENSIVE DATA CLEANUP
-- ============================================================================

-- Delete all questions for categories we're about to insert (by name)
DELETE FROM job_category_questions WHERE category_id IN (
    SELECT id FROM job_categories WHERE name IN (
        'House Cleaning', 'Deep Cleaning', 'Gardening', 'Cooking', 'Elderly Care',
        'Child Care', 'Pet Care', 'Tutoring', 'Tech Support', 'Moving Help'
    )
);

-- Delete all existing categories with these names
DELETE FROM job_categories WHERE name IN (
    'House Cleaning', 'Deep Cleaning', 'Gardening', 'Cooking', 'Elderly Care',
    'Child Care', 'Pet Care', 'Tutoring', 'Tech Support', 'Moving Help'
);

-- ============================================================================
-- JOB CATEGORIES SEED DATA (INSERT FIRST)
-- ============================================================================

INSERT INTO job_categories (id, name, description, default_hourly_rate, is_active) VALUES 
('550e8400-e29b-41d4-a716-446655440001', 'House Cleaning', 'General house cleaning services including dusting, mopping, and organizing', 2500.00, true),
('550e8400-e29b-41d4-a716-446655440002', 'Deep Cleaning', 'Thorough deep cleaning services for homes and offices', 3000.00, true),
('550e8400-e29b-41d4-a716-446655440003', 'Gardening', 'Garden maintenance, landscaping, and plant care services', 2000.00, true),
('550e8400-e29b-41d4-a716-446655440004', 'Cooking', 'Meal preparation and cooking services for events or daily meals', 2200.00, true),
('550e8400-e29b-41d4-a716-446655440005', 'Elderly Care', 'Care and assistance for elderly individuals including companionship', 2800.00, true),
('550e8400-e29b-41d4-a716-446655440006', 'Child Care', 'Babysitting and child care services for families', 2400.00, true),
('550e8400-e29b-41d4-a716-446655440007', 'Pet Care', 'Pet sitting, walking, and general pet care services', 1800.00, true),
('550e8400-e29b-41d4-a716-446655440008', 'Tutoring', 'Educational tutoring and homework assistance', 3500.00, true),
('550e8400-e29b-41d4-a716-446655440009', 'Tech Support', 'Computer and technology assistance services', 4000.00, true),
('550e8400-e29b-41d4-a716-446655440010', 'Moving Help', 'Assistance with packing, moving, and organizing', 2800.00, true);

-- ============================================================================
-- JOB CATEGORY QUESTIONS SEED DATA (INSERT AFTER CATEGORIES)
-- ============================================================================

-- House Cleaning Questions
INSERT INTO job_category_questions (id, category_id, question, question_text, question_type, is_required, order_index, question_order) VALUES 
('650e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'How many rooms need cleaning?', 'How many rooms need cleaning?', 'number', true, 1, 1),
('650e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'Do you have cleaning supplies?', 'Do you have cleaning supplies?', 'text', true, 2, 2),
('650e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', 'Any specific cleaning requirements?', 'Any specific cleaning requirements?', 'text', false, 3, 3),
('650e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440001', 'Are there pets in the house?', 'Are there pets in the house?', 'text', false, 4, 4);

-- Deep Cleaning Questions
INSERT INTO job_category_questions (id, category_id, question, question_text, question_type, is_required, order_index, question_order) VALUES 
('650e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440002', 'What areas need deep cleaning?', 'What areas need deep cleaning?', 'text', true, 1, 1),
('650e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440002', 'How long since last deep clean?', 'How long since last deep clean?', 'text', false, 2, 2),
('650e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440002', 'Any stubborn stains or problem areas?', 'Any stubborn stains or problem areas?', 'text', false, 3, 3);

-- Gardening Questions
INSERT INTO job_category_questions (id, category_id, question, question_text, question_type, is_required, order_index, question_order) VALUES 
('650e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440003', 'What type of gardening work is needed?', 'What type of gardening work is needed?', 'text', true, 1, 1),
('650e8400-e29b-41d4-a716-446655440009', '550e8400-e29b-41d4-a716-446655440003', 'Size of garden/area?', 'Size of garden/area?', 'text', false, 2, 2),
('650e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440003', 'Do you have gardening tools?', 'Do you have gardening tools?', 'text', false, 3, 3);

-- Cooking Questions
INSERT INTO job_category_questions (id, category_id, question, question_text, question_type, is_required, order_index, question_order) VALUES 
('650e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440004', 'How many people will be served?', 'How many people will be served?', 'number', true, 1, 1),
('650e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440004', 'Any dietary restrictions?', 'Any dietary restrictions?', 'text', false, 2, 2),
('650e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440004', 'Type of cuisine preferred?', 'Type of cuisine preferred?', 'text', false, 3, 3);

-- Elderly Care Questions
INSERT INTO job_category_questions (id, category_id, question, question_text, question_type, is_required, order_index, question_order) VALUES 
('650e8400-e29b-41d4-a716-446655440014', '550e8400-e29b-41d4-a716-446655440005', 'What type of care is needed?', 'What type of care is needed?', 'text', true, 1, 1),
('650e8400-e29b-41d4-a716-446655440015', '550e8400-e29b-41d4-a716-446655440005', 'Any medical conditions to consider?', 'Any medical conditions to consider?', 'text', false, 2, 2),
('650e8400-e29b-41d4-a716-446655440016', '550e8400-e29b-41d4-a716-446655440005', 'Mobility assistance required?', 'Mobility assistance required?', 'text', false, 3, 3);

-- Child Care Questions
INSERT INTO job_category_questions (id, category_id, question, question_text, question_type, is_required, order_index, question_order) VALUES 
('650e8400-e29b-41d4-a716-446655440017', '550e8400-e29b-41d4-a716-446655440006', 'Age of children?', 'Age of children?', 'text', true, 1, 1),
('650e8400-e29b-41d4-a716-446655440018', '550e8400-e29b-41d4-a716-446655440006', 'Number of children?', 'Number of children?', 'number', true, 2, 2),
('650e8400-e29b-41d4-a716-446655440019', '550e8400-e29b-41d4-a716-446655440006', 'Any special needs or allergies?', 'Any special needs or allergies?', 'text', false, 3, 3);

-- Pet Care Questions
INSERT INTO job_category_questions (id, category_id, question, question_text, question_type, is_required, order_index, question_order) VALUES 
('650e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440007', 'What type of pets?', 'What type of pets?', 'text', true, 1, 1),
('650e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440007', 'Number of pets?', 'Number of pets?', 'number', true, 2, 2),
('650e8400-e29b-41d4-a716-446655440022', '550e8400-e29b-41d4-a716-446655440007', 'Any special care requirements?', 'Any special care requirements?', 'text', false, 3, 3);

-- Tutoring Questions
INSERT INTO job_category_questions (id, category_id, question, question_text, question_type, is_required, order_index, question_order) VALUES 
('650e8400-e29b-41d4-a716-446655440023', '550e8400-e29b-41d4-a716-446655440008', 'What subject(s) need tutoring?', 'What subject(s) need tutoring?', 'text', true, 1, 1),
('650e8400-e29b-41d4-a716-446655440024', '550e8400-e29b-41d4-a716-446655440008', 'Student grade level?', 'Student grade level?', 'text', true, 2, 2),
('650e8400-e29b-41d4-a716-446655440025', '550e8400-e29b-41d4-a716-446655440008', 'Specific learning goals?', 'Specific learning goals?', 'text', false, 3, 3);

-- Tech Support Questions
INSERT INTO job_category_questions (id, category_id, question, question_text, question_type, is_required, order_index, question_order) VALUES 
('650e8400-e29b-41d4-a716-446655440026', '550e8400-e29b-41d4-a716-446655440009', 'What type of tech issue?', 'What type of tech issue?', 'text', true, 1, 1),
('650e8400-e29b-41d4-a716-446655440027', '550e8400-e29b-41d4-a716-446655440009', 'Device type (computer, phone, etc.)?', 'Device type (computer, phone, etc.)?', 'text', true, 2, 2),
('650e8400-e29b-41d4-a716-446655440028', '550e8400-e29b-41d4-a716-446655440009', 'Urgency level?', 'Urgency level?', 'text', false, 3, 3);

-- Moving Help Questions
INSERT INTO job_category_questions (id, category_id, question, question_text, question_type, is_required, order_index, question_order) VALUES 
('650e8400-e29b-41d4-a716-446655440029', '550e8400-e29b-41d4-a716-446655440010', 'Size of move (studio, 1BR, 2BR, etc.)?', 'Size of move (studio, 1BR, 2BR, etc.)?', 'text', true, 1, 1),
('650e8400-e29b-41d4-a716-446655440030', '550e8400-e29b-41d4-a716-446655440010', 'Heavy furniture involved?', 'Heavy furniture involved?', 'text', true, 2, 2),
('650e8400-e29b-41d4-a716-446655440031', '550e8400-e29b-41d4-a716-446655440010', 'Distance of move?', 'Distance of move?', 'text', false, 3, 3); 