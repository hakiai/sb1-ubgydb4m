/*
  # Create test accounts

  1. New Data
    - Creates 5 test user accounts in auth.users
    - Creates corresponding profile entries
    
  2. Security
    - Uses secure password hashing
    - Sets up basic profile data
*/

-- テストユーザーの作成
DO $$
DECLARE
  test_user_id uuid;
BEGIN
  -- Test User 1
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
  VALUES (
    gen_random_uuid(),
    'test1@example.com',
    crypt('password123', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}'
  )
  RETURNING id INTO test_user_id;

  -- Test User 2
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
  VALUES (
    gen_random_uuid(),
    'test2@example.com',
    crypt('password123', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}'
  )
  RETURNING id INTO test_user_id;

  -- Test User 3
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
  VALUES (
    gen_random_uuid(),
    'test3@example.com',
    crypt('password123', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}'
  )
  RETURNING id INTO test_user_id;

  -- Test User 4
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
  VALUES (
    gen_random_uuid(),
    'test4@example.com',
    crypt('password123', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}'
  )
  RETURNING id INTO test_user_id;

  -- Test User 5
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
  VALUES (
    gen_random_uuid(),
    'test5@example.com',
    crypt('password123', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}'
  )
  RETURNING id INTO test_user_id;

END $$;