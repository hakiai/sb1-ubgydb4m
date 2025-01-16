-- フレンドシップテーブルの修正
DROP TABLE IF EXISTS friendships CASCADE;

CREATE TABLE friendships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  friend_id uuid NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'accepted')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, friend_id),
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  FOREIGN KEY (friend_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- RLSの有効化
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- フレンドシップのポリシー
CREATE POLICY "フレンドシップの参照"
  ON friendships
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR friend_id = auth.uid());

CREATE POLICY "フレンドリクエストの送信"
  ON friendships
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "フレンドシップの更新"
  ON friendships
  FOR UPDATE
  TO authenticated
  USING (friend_id = auth.uid())
  WITH CHECK (friend_id = auth.uid());

-- テストユーザー間のフレンドシップを作成
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
  IF test_user1_id IS NOT NULL AND test_user2_id IS NOT NULL THEN
    INSERT INTO friendships (user_id, friend_id, status)
    VALUES
      (test_user1_id, test_user2_id, 'accepted'),
      (test_user2_id, test_user1_id, 'accepted')
    ON CONFLICT (user_id, friend_id) DO NOTHING;
  END IF;

  IF test_user1_id IS NOT NULL AND test_user3_id IS NOT NULL THEN
    INSERT INTO friendships (user_id, friend_id, status)
    VALUES
      (test_user1_id, test_user3_id, 'accepted'),
      (test_user3_id, test_user1_id, 'accepted')
    ON CONFLICT (user_id, friend_id) DO NOTHING;
  END IF;
END $$;