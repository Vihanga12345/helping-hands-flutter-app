-- Helping Hands App - Seed Data
-- Run this AFTER creating the schema
-- Copy and paste this into Supabase SQL Editor after running the schema

-- Insert Job Categories (matching the app's job types)
INSERT INTO job_categories (id, name, description, icon_name) VALUES
(uuid_generate_v4(), 'House Cleaning', 'General house cleaning services including dusting, vacuuming, and sanitizing', 'cleaning_services'),
(uuid_generate_v4(), 'Deep Cleaning', 'Thorough deep cleaning for homes and offices', 'cleaning_services'),
(uuid_generate_v4(), 'Gardening', 'Garden maintenance, landscaping, and plant care', 'yard_work'),
(uuid_generate_v4(), 'Pet Care', 'Pet sitting, walking, feeding, and grooming services', 'pets'),
(uuid_generate_v4(), 'Elderly Care', 'Companion care and assistance for elderly individuals', 'elderly_care'),
(uuid_generate_v4(), 'Tutoring', 'Educational tutoring and homework assistance', 'school'),
(uuid_generate_v4(), 'Tech Support', 'Computer troubleshooting and technical assistance', 'computer'),
(uuid_generate_v4(), 'Photography', 'Event photography and photo editing services', 'camera_alt'),
(uuid_generate_v4(), 'Fitness Training', 'Personal fitness training and workout guidance', 'fitness_center'),
(uuid_generate_v4(), 'Cooking', 'Meal preparation and cooking services', 'restaurant'),
(uuid_generate_v4(), 'Laundry', 'Washing, drying, and folding clothes', 'local_laundry_service'),
(uuid_generate_v4(), 'Plumbing', 'Basic plumbing repairs and maintenance', 'plumbing'),
(uuid_generate_v4(), 'Electrical Work', 'Basic electrical repairs and installations', 'electrical_services'),
(uuid_generate_v4(), 'Painting', 'Interior and exterior painting services', 'format_paint'),
(uuid_generate_v4(), 'Moving Help', 'Assistance with packing and moving', 'local_shipping'),
(uuid_generate_v4(), 'Furniture Assembly', 'Assembly of furniture and household items', 'construction'),
(uuid_generate_v4(), 'Car Washing', 'Vehicle cleaning and detailing services', 'local_car_wash'),
(uuid_generate_v4(), 'Delivery Services', 'Package and food delivery', 'delivery_dining'),
(uuid_generate_v4(), 'Event Planning', 'Party and event organization assistance', 'event'),
(uuid_generate_v4(), 'Shopping Assistance', 'Grocery shopping and errands', 'shopping_cart'),
(uuid_generate_v4(), 'Office Maintenance', 'Office cleaning and maintenance services', 'business'),
(uuid_generate_v4(), 'Babysitting', 'Child care and supervision services', 'child_care'),
(uuid_generate_v4(), 'Window Cleaning', 'Professional window cleaning services', 'cleaning_services'),
(uuid_generate_v4(), 'Carpet Cleaning', 'Carpet and upholstery cleaning', 'cleaning_services'),
(uuid_generate_v4(), 'Appliance Repair', 'Basic appliance troubleshooting and repair', 'home_repair_service'),
(uuid_generate_v4(), 'Massage Therapy', 'Therapeutic massage and wellness services', 'spa'),
(uuid_generate_v4(), 'Language Translation', 'Document translation and interpretation', 'translate'),
(uuid_generate_v4(), 'Music Lessons', 'Musical instrument lessons and music theory', 'music_note'),
(uuid_generate_v4(), 'Art and Craft', 'Art lessons and creative workshops', 'palette'),
(uuid_generate_v4(), 'Data Entry', 'Administrative and data entry services', 'keyboard');

-- Create sample admin user (for testing purposes)
INSERT INTO users (id, email, phone, first_name, last_name, user_type, is_verified, is_active) VALUES
(uuid_generate_v4(), 'admin@helpinghands.com', '+94771234567', 'System', 'Administrator', 'admin', true, true);

-- Verify the data was inserted correctly
SELECT 'Job Categories Created:' as message, COUNT(*) as count FROM job_categories;
SELECT 'Admin User Created:' as message, COUNT(*) as count FROM users WHERE user_type = 'admin'; 