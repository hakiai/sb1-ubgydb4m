/*
  # Fix friends query relationships

  1. Changes
    - Add explicit foreign key references between friendships and profiles
    - Update RLS policies for better security
*/

-- プロフィールテーブルへの外部キー参照を明示的に追加
ALTER TABLE friendships
DROP CONSTRAINT IF EXISTS friendships_user_id_fkey,
DROP CONSTRAINT IF EXISTS friendships_friend_id_fkey;

ALTER TABLE friendships
ADD CONSTRAINT friendships_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE,
ADD CONSTRAINT friendships_friend_id_fkey
  FOREIGN KEY (friend_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- プロフィールの参照ポリシーを更新
CREATE POLICY "全てのユーザーがプロフィールを参照できる"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (true);

-- フレンドシップのポリシーを更新
DROP POLICY IF EXISTS "ユーザーは自分のフレンドシップを参照できる" ON friendships;
DROP POLICY IF EXISTS "ユーザーはフレンドリクエストを送信できる" ON friendships;
DROP POLICY IF EXISTS "ユーザーは自分のフレンドシップを更新できる" ON friendships;

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