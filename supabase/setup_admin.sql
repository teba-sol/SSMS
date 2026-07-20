-- =============================================================================
-- SSCS: Setup Admin User
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- =============================================================================
-- Default admin credentials:
--   Email:    tebibu@gmail.com
--   Password: 123@teba
-- =============================================================================

-- Step 1: Create the auth user (skip if already exists)
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'tebibu@gmail.com',
    crypt('123@teba', gen_salt('bf')),
    now(),
    '{"provider": "email", "providers": ["email"]}',
    '{"first_name": "Tebibu", "last_name": "Admin", "role": "administrator"}',
    now(),
    now()
)
ON CONFLICT (email) DO NOTHING;

-- Step 2: Create the profile (skip if already exists)
INSERT INTO profiles (
    id,
    email,
    first_name,
    last_name,
    role,
    is_active,
    email_verified,
    created_at,
    updated_at
)
SELECT
    id,
    'tebibu@gmail.com',
    'Tebibu',
    'Admin',
    'administrator'::user_role,
    true,
    true,
    now(),
    now()
FROM auth.users
WHERE email = 'tebibu@gmail.com'
ON CONFLICT (id) DO NOTHING;

-- Step 3: Create a current academic year if none exists
INSERT INTO academic_years (
    name,
    start_date,
    end_date,
    is_current,
    created_at,
    updated_at
)
SELECT
    '2025-2026',
    '2025-09-01',
    '2026-07-31',
    true,
    now(),
    now()
WHERE NOT EXISTS (
    SELECT 1 FROM academic_years WHERE is_current = true
)
ON CONFLICT (name) DO NOTHING;

-- Step 4: Create default subjects if none exist
INSERT INTO subjects (name, code, description, is_active, created_at)
SELECT * FROM (VALUES
    ('Mathematics', 'MATH', 'Mathematics', true, now()),
    ('English', 'ENG', 'English Language', true, now()),
    ('Science', 'SCI', 'General Science', true, now()),
    ('Social Studies', 'SOC', 'Social Studies', true, now()),
    ('Physical Education', 'PE', 'Physical Education', true, now())
) AS v(name, code, description, is_active, created_at)
WHERE NOT EXISTS (SELECT 1 FROM subjects LIMIT 1)
ON CONFLICT (name) DO NOTHING;

-- =============================================================================
-- DONE! You can now log in with:
--   Email:    tebibu@gmail.com
--   Password: 123@teba
-- =============================================================================
