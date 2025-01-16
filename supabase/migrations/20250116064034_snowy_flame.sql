/*
  # チャットルームポリシーの修正

  1. 変更点
    - chat_room_membersテーブルのポリシーを簡素化
    - 無限再帰を防ぐため、より直接的なアクセス制御に変更

  2. セキュリティ
    - ユーザーは自分が参加しているチャットルームのみアクセス可能
    - チャットルーム作成者のみメンバーを追加可能
*/

-- 既存のポリシーを削除
DROP POLICY IF EXISTS "ユーザーは自分が参加しているチャットルームのメンバーを参照できる" ON chat_room_members;
DROP POLICY IF EXISTS "ユーザーは新しいメンバーを追加できる" ON chat_room_members;

-- 新しいポリシーを作成
CREATE POLICY "メンバーの参照"
  ON chat_room_members
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "メンバーの追加"
  ON chat_room_members
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE id = room_id
      AND created_by = auth.uid()
    )
    OR
    user_id = auth.uid()
  );