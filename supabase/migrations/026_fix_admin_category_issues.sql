-- Migration: Fix Admin Category Issues
-- Date: 2024-01-20
-- Purpose: Fix timestamp issues, missing admin users, and function problems

-- 1. Insert the fallback admin user into admin_users table
INSERT INTO admin_users (
    id, 
    username, 
    email,
    password_hash, 
    full_name, 
    is_active, 
    created_at, 
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'admin',
    'admin@helpinghands.com',
    '$2b$12$LQv3c1yX8O2iCDe6OqHzLuA4EhAV8cNj2tJ8tY6nZp9qWZzKjL8uO', -- admin123 hashed
    'System Administrator',
    true,
    NOW(),
    NOW()
) ON CONFLICT (username) DO UPDATE SET
    id = EXCLUDED.id,
    email = EXCLUDED.email,
    password_hash = EXCLUDED.password_hash,
    full_name = EXCLUDED.full_name,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

-- 2. Drop and recreate the problematic function with correct types
DROP FUNCTION IF EXISTS admin_get_all_categories();

CREATE OR REPLACE FUNCTION admin_get_all_categories()
RETURNS TABLE (
    id UUID,
    name VARCHAR(255),
    description TEXT,
    default_hourly_rate DECIMAL(10,2),
    icon_name VARCHAR(100),
    is_active BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    question_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        jc.id,
        jc.name,
        jc.description,
        jc.default_hourly_rate,
        jc.icon_name,
        jc.is_active,
        jc.created_at,
        jc.updated_at,
        COALESCE(COUNT(jcq.id), 0) as question_count
    FROM job_categories jc
    LEFT JOIN job_category_questions jcq ON jc.id = jcq.category_id AND jcq.is_active = true
    WHERE jc.is_active = true
    GROUP BY jc.id, jc.name, jc.description, jc.default_hourly_rate, jc.icon_name, jc.is_active, jc.created_at, jc.updated_at
    ORDER BY jc.name;
END;
$$ LANGUAGE plpgsql;

-- 3. Fix the admin_get_category_questions function
DROP FUNCTION IF EXISTS admin_get_category_questions(UUID);

CREATE OR REPLACE FUNCTION admin_get_category_questions(p_category_id UUID)
RETURNS TABLE (
    id UUID,
    question TEXT,
    question_order INTEGER,
    is_required BOOLEAN,
    placeholder_text TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        jcq.id,
        jcq.question,
        jcq.question_order,
        jcq.is_required,
        jcq.placeholder_text,
        jcq.created_at,
        jcq.updated_at
    FROM job_category_questions jcq
    WHERE jcq.category_id = p_category_id 
    AND jcq.is_active = true
    ORDER BY jcq.question_order;
END;
$$ LANGUAGE plpgsql;

-- 4. Fix the admin_create_job_category function
DROP FUNCTION IF EXISTS admin_create_job_category(VARCHAR, TEXT, DECIMAL, UUID, VARCHAR);

CREATE OR REPLACE FUNCTION admin_create_job_category(
    p_name VARCHAR(255),
    p_description TEXT,
    p_default_hourly_rate DECIMAL(10,2),
    p_admin_id UUID,
    p_icon_name VARCHAR(100) DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    new_category_id UUID;
BEGIN
    INSERT INTO job_categories (
        name,
        description,
        default_hourly_rate,
        icon_name,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        p_name,
        p_description,
        p_default_hourly_rate,
        p_icon_name,
        true,
        NOW(),
        NOW()
    ) RETURNING id INTO new_category_id;

    -- Log the action if audit table exists
    BEGIN
        INSERT INTO admin_audit_log (
            admin_user_id,
            action_type,
            entity_type,
            entity_id,
            entity_name,
            action_details,
            created_at
        ) VALUES (
            p_admin_id,
            'create',
            'job_category',
            new_category_id,
            p_name,
            jsonb_build_object(
                'name', p_name,
                'description', p_description,
                'default_hourly_rate', p_default_hourly_rate,
                'icon_name', p_icon_name
            ),
            NOW()
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Ignore audit logging errors
            NULL;
    END;

    RETURN new_category_id;
END;
$$ LANGUAGE plpgsql;

-- 5. Fix the admin_update_job_category function
DROP FUNCTION IF EXISTS admin_update_job_category(UUID, VARCHAR, TEXT, DECIMAL, UUID, VARCHAR);

CREATE OR REPLACE FUNCTION admin_update_job_category(
    p_category_id UUID,
    p_name VARCHAR(255),
    p_description TEXT,
    p_default_hourly_rate DECIMAL(10,2),
    p_admin_id UUID,
    p_icon_name VARCHAR(100) DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    old_record RECORD;
BEGIN
    -- Get old values for audit
    SELECT * INTO old_record FROM job_categories WHERE id = p_category_id;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;

    UPDATE job_categories SET
        name = p_name,
        description = p_description,
        default_hourly_rate = p_default_hourly_rate,
        icon_name = p_icon_name,
        updated_at = NOW()
    WHERE id = p_category_id;

    -- Log the action if audit table exists
    BEGIN
        INSERT INTO admin_audit_log (
            admin_user_id,
            action_type,
            entity_type,
            entity_id,
            entity_name,
            action_details,
            old_values,
            new_values,
            created_at
        ) VALUES (
            p_admin_id,
            'update',
            'job_category',
            p_category_id,
            p_name,
            jsonb_build_object('updated_fields', ARRAY['name', 'description', 'default_hourly_rate', 'icon_name']),
            row_to_json(old_record)::jsonb,
            jsonb_build_object(
                'name', p_name,
                'description', p_description,
                'default_hourly_rate', p_default_hourly_rate,
                'icon_name', p_icon_name
            ),
            NOW()
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Ignore audit logging errors
            NULL;
    END;

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- 6. Fix the admin_add_category_question function
DROP FUNCTION IF EXISTS admin_add_category_question(UUID, TEXT, UUID, BOOLEAN, TEXT);

CREATE OR REPLACE FUNCTION admin_add_category_question(
    p_category_id UUID,
    p_question TEXT,
    p_admin_id UUID,
    p_is_required BOOLEAN DEFAULT true,
    p_placeholder_text TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    new_question_id UUID;
    next_order INTEGER;
BEGIN
    -- Get next order number
    SELECT COALESCE(MAX(question_order), 0) + 1 
    INTO next_order 
    FROM job_category_questions 
    WHERE category_id = p_category_id;

    INSERT INTO job_category_questions (
        category_id,
        question,
        question_order,
        is_required,
        placeholder_text,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        p_category_id,
        p_question,
        next_order,
        p_is_required,
        p_placeholder_text,
        true,
        NOW(),
        NOW()
    ) RETURNING id INTO new_question_id;

    -- Log the action if audit table exists
    BEGIN
        INSERT INTO admin_audit_log (
            admin_user_id,
            action_type,
            entity_type,
            entity_id,
            entity_name,
            action_details,
            created_at
        ) VALUES (
            p_admin_id,
            'create',
            'job_category_question',
            new_question_id,
            p_question,
            jsonb_build_object(
                'category_id', p_category_id,
                'question', p_question,
                'is_required', p_is_required,
                'placeholder_text', p_placeholder_text
            ),
            NOW()
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Ignore audit logging errors
            NULL;
    END;

    RETURN new_question_id;
END;
$$ LANGUAGE plpgsql; 