-- Helping Hands App - Seed Data
-- Migration: 002_seed_data.sql

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

-- Note: In production, real users will be created through the app's registration process
-- The following are just examples of the data structure:

/*
Example Helper User:
INSERT INTO users (email, phone, first_name, last_name, user_type, gender, about_me, location_address, location_city) VALUES
('john.helper@email.com', '+94771234568', 'John', 'Smith', 'helper', 'male', 'Experienced cleaner with 5 years of experience', '123 Main St, Colombo', 'Colombo');

Example Helpee User:
INSERT INTO users (email, phone, first_name, last_name, user_type, gender, location_address, location_city) VALUES
('jane.helpee@email.com', '+94771234569', 'Jane', 'Doe', 'helpee', 'female', '456 Oak Ave, Kandy', 'Kandy');

Example Helper Skills:
INSERT INTO user_skills (user_id, category_id, experience_years, skill_level, hourly_rate) VALUES
((SELECT id FROM users WHERE email = 'john.helper@email.com'), 
 (SELECT id FROM job_categories WHERE name = 'House Cleaning'), 
 5, 'advanced', 2500.00);

Example Job Posting:
INSERT INTO jobs (helpee_id, category_id, title, description, job_type, hourly_rate, scheduled_date, scheduled_start_time, location_latitude, location_longitude, location_address) VALUES
((SELECT id FROM users WHERE email = 'jane.helpee@email.com'),
 (SELECT id FROM job_categories WHERE name = 'House Cleaning'),
 'Weekly house cleaning needed',
 'Looking for someone to clean my 3-bedroom apartment weekly',
 'public', 2000.00, '2024-12-30', '10:00:00', 6.9271, 79.8612, '456 Oak Ave, Kandy');
*/ 