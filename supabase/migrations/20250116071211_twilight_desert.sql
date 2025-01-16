/*
  # テストユーザー間のフレンドシップを作成

  1. Changes
    - username: 'test' のユーザーと他の2人のテストユーザーとのフレンドシップを作成
*/

DO $$
DECLARE
  test_user_id uuid;
  test_user1_id uuid;
  test_user2_id uuid;
BEGIN
  -- Get user IDs
  SELECT id INTO test_user_id FROM profiles WHERE username = 'test' LIMIT 1;
  SELECT id INTO test_user1_id FROM profiles WHERE email = 'test1@example.com' LIMIT 1;
  SELECT id INTO test_user2_id FROM profiles WHERE email = 'test2@example.com' LIMIT 1;

  -- Create friendships (bidirectional)
  IF test_user_id IS NOT NULL AND test_user1_id IS NOT NULL THEN
    INSERT INTO friendships (user_id, friend_id, status)
    VALUES
      (test_user_id, test_user1_id, 'accepted'),
      (test_user1_id, test_user_id, 'accepted')
    ON CONFLICT (user_id, friend_id) DO NOTHING;
  END IF;

  IF test_user_id IS NOT NULL AND test_user2_id IS NOT NULL THEN
    INSERT INTO friendships (user_id, friend_id, status)
    VALUES
      (test_user_id, test_user2_id, 'accepted'),
      (test_user2_id, test_user_id, 'accepted')
    ON CONFLICT (user_id, friend_id) DO NOTHING;
  END IF;
END $$;