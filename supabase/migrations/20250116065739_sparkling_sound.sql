/*
  # テストユーザー間のフレンドシップ作成

  1. 変更内容
    - テストユーザー間のフレンドシップを作成
    - 承認済みの状態で設定

  2. セキュリティ
    - 既存のRLSポリシーを使用
*/

DO $$
DECLARE
  test_user1_id uuid;
  test_user2_id uuid;
  test_user3_id uuid;
BEGIN
  -- テストユーザーのIDを取得
  SELECT id INTO test_user1_id FROM auth.users WHERE email = 'test1@example.com' LIMIT 1;
  SELECT id INTO test_user2_id FROM auth.users WHERE email = 'test2@example.com' LIMIT 1;
  SELECT id INTO test_user3_id FROM auth.users WHERE email = 'test3@example.com' LIMIT 1;

  -- フレンドシップを作成（双方向）
  -- test1 と test2
  INSERT INTO friendships (user_id, friend_id, status)
  VALUES
    (test_user1_id, test_user2_id, 'accepted'),
    (test_user2_id, test_user1_id, 'accepted')
  ON CONFLICT (user_id, friend_id) DO NOTHING;

  -- test1 と test3
  INSERT INTO friendships (user_id, friend_id, status)
  VALUES
    (test_user1_id, test_user3_id, 'accepted'),
    (test_user3_id, test_user1_id, 'accepted')
  ON CONFLICT (user_id, friend_id) DO NOTHING;
END $$;