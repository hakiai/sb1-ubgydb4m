/*
  # メッセージテーブルのRLSポリシー修正

  1. Changes
    - メッセージの参照ポリシーを更新
    - メッセージの作成ポリシーを更新
    - チャットルームメンバーに基づくアクセス制御を実装
*/

-- 既存のメッセージポリシーを削除
DROP POLICY IF EXISTS "ユーザーは自分のメッセージを読み取れる" ON messages;
DROP POLICY IF EXISTS "ユーザーは新しいメッセージを作成できる" ON messages;
DROP POLICY IF EXISTS "ユーザーは参加しているチャットルームのメッセージを参照できる" ON messages;
DROP POLICY IF EXISTS "ユーザーは参加しているチャットルームにメッセージを送信できる" ON messages;

-- メッセージの参照ポリシー
CREATE POLICY "メッセージの参照"
  ON messages
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM chat_room_members
      WHERE room_id = messages.room_id
      AND user_id = auth.uid()
    )
  );

-- メッセージの作成ポリシー
CREATE POLICY "メッセージの作成"
  ON messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chat_room_members
      WHERE room_id = messages.room_id
      AND user_id = auth.uid()
    )
  );

-- メッセージの更新ポリシー
CREATE POLICY "メッセージの更新"
  ON messages
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- メッセージの削除ポリシー
CREATE POLICY "メッセージの削除"
  ON messages
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());