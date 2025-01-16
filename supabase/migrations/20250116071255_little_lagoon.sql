/*
  # チャットルームのRLSポリシーを修正

  1. Changes
    - チャットルームのRLSポリシーを更新
    - メンバーのRLSポリシーを更新
*/

-- チャットルームのRLSポリシーを更新
DROP POLICY IF EXISTS "ユーザーは参加しているチャットルームを参照できる" ON chat_rooms;
DROP POLICY IF EXISTS "ユーザーは新しいチャットルームを作成できる" ON chat_rooms;

CREATE POLICY "チャットルームの参照"
  ON chat_rooms
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM chat_room_members
      WHERE room_id = id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "チャットルームの作成"
  ON chat_rooms
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- チャットルームメンバーのRLSポリシーを更新
DROP POLICY IF EXISTS "メンバーの参照" ON chat_room_members;
DROP POLICY IF EXISTS "メンバーの追加" ON chat_room_members;

CREATE POLICY "メンバーの参照"
  ON chat_room_members
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM chat_room_members
      WHERE room_id = chat_room_members.room_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "メンバーの追加"
  ON chat_room_members
  FOR INSERT
  TO authenticated
  WITH CHECK (true);