/*
  # チャットルームのRLSポリシーを修正

  1. Changes
    - チャットルームのRLSポリシーを単純化
    - 作成と参照のポリシーを明確に分離
*/

-- チャットルームのRLSポリシーを更新
DROP POLICY IF EXISTS "チャットルームの参照" ON chat_rooms;
DROP POLICY IF EXISTS "チャットルームの作成" ON chat_rooms;

-- 参照ポリシー
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

-- 作成ポリシー
CREATE POLICY "チャットルームの作成"
  ON chat_rooms
  FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

-- チャットルームメンバーのポリシーを更新
DROP POLICY IF EXISTS "メンバーの参照" ON chat_room_members;
DROP POLICY IF EXISTS "メンバーの追加" ON chat_room_members;

-- メンバー参照ポリシー
CREATE POLICY "メンバーの参照"
  ON chat_room_members
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- メンバー追加ポリシー
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
    OR user_id = auth.uid()
  );