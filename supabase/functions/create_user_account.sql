-- Run this SQL in Supabase SQL Editor (https://supabase.com/dashboard → SQL Editor)
-- This creates an RPC function that replaces the create-user Edge Function

CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.create_user_account(
  p_email TEXT,
  p_first_name TEXT,
  p_last_name TEXT,
  p_role TEXT,
  p_phone TEXT DEFAULT NULL,
  p_employee_id TEXT DEFAULT NULL,
  p_department TEXT DEFAULT NULL,
  p_qualification TEXT DEFAULT NULL,
  p_hire_date TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_user_id UUID;
  v_temp_password TEXT;
  v_profile_role TEXT;
  v_role user_role;
BEGIN
  -- Verify caller is an administrator
  SELECT role INTO v_profile_role
  FROM profiles
  WHERE id = auth.uid();

  IF v_profile_role != 'administrator' THEN
    RAISE EXCEPTION 'Only administrators can create users';
  END IF;

  -- Validate inputs
  IF p_email IS NULL OR p_first_name IS NULL OR p_last_name IS NULL OR p_role IS NULL THEN
    RAISE EXCEPTION 'email, firstName, lastName, and role are required';
  END IF;

  IF p_role NOT IN ('teacher', 'parent') THEN
    RAISE EXCEPTION 'role must be teacher or parent';
  END IF;

  -- Cast role to the enum type
  v_role := p_role::user_role;

  -- Generate a temporary password
  v_temp_password := 'Temp_' || substr(md5(random()::text), 1, 12) || '!1';

  -- Create auth user using the auth schema directly
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change_token_new,
    email_change
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    p_email,
    crypt(v_temp_password, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    json_build_object('first_name', p_first_name, 'last_name', p_last_name),
    NOW(),
    NOW(),
    '',
    '',
    ''
  )
  RETURNING id INTO v_user_id;

  -- Create identity record
  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_user_id,
    json_build_object('sub', v_user_id, 'email', p_email),
    'email',
    p_email,
    NOW(),
    NOW(),
    NOW()
  );

  -- Create sessions entry
  INSERT INTO auth.sessions (
    id,
    user_id,
    created_at,
    updated_at,
    factor_id,
    aal,
    not_after
  ) VALUES (
    gen_random_uuid(),
    v_user_id,
    NOW(),
    NOW(),
    NULL,
    'aal1',
    NOW() + INTERVAL '7 days'
  );

  -- Create profile
  INSERT INTO profiles (
    id,
    email,
    first_name,
    last_name,
    role,
    phone,
    is_active,
    created_by
  ) VALUES (
    v_user_id,
    p_email,
    p_first_name,
    p_last_name,
    v_role,
    p_phone,
    TRUE,
    auth.uid()
  );

  -- Create role-specific record
  IF p_role = 'teacher' THEN
    IF p_employee_id IS NULL THEN
      RAISE EXCEPTION 'employeeId is required for teachers';
    END IF;

    INSERT INTO teachers (
      profile_id,
      employee_id,
      department,
      qualification,
      hire_date,
      is_active,
      created_by
    ) VALUES (
      v_user_id,
      p_employee_id,
      p_department,
      p_qualification,
      p_hire_date::date,
      TRUE,
      auth.uid()
    );
  END IF;

  RETURN json_build_object(
    'userId', v_user_id,
    'tempPassword', v_temp_password,
    'message', 'User created successfully'
  );

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;

-- Allow authenticated users to call this function
GRANT EXECUTE ON FUNCTION public.create_user_account TO authenticated;


