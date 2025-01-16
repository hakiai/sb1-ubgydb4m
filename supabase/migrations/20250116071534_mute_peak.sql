/*
  # チャットルームとメンバーのRLSポリシー最終修正

  1. Changes
    - チャットルームのRLSポリシーを完全に見直し
    - チャットルームメンバーのRLSポリシーを簡素化
    - 各テーブルのポリシーを明確に分離
*/

-- チャットルームのRLSポリシーを更新
DROP POLICY IF EXISTS "チャットルームの参照" ON chat_rooms;
DROP POLICY IF EXISTS "チャットルームの作成" ON chat_rooms;

-- チャットルームの参照ポリシー
CREATE POLICY "チャットルームの参照"
  ON chat_rooms
  FOR SELECT
  TO authenticated
  USING (true);

-- チャットルームの作成ポリシー
CREATE POLICY "チャットルームの作成"
  ON chat_rooms
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- チャットルームの更新ポリシー
CREATE POLICY "チャットルームの更新"
  ON chat_rooms
  FOR UPDATE
  TO authenticated
  USING (created_by = auth.uid());

-- チャットルームの削除ポリシー
CREATE POLICY "チャットルームの削除"
  ON chat_rooms
  FOR DELETE
  TO authenticated
  USING (created_by = auth.uid());

-- チャットルームメンバーのポリシーを更新
DROP POLICY IF EXISTS "メンバーの参照" ON chat_room_members;
DROP POLICY IF EXISTS "メンバーの追加" ON chat_room_members;

-- メンバーの参照ポリシー
CREATE POLICY "メンバーの参照"
  ON chat_room_members
  FOR SELECT
  TO authenticated
  USING (true);

-- メンバーの追加ポリシー
CREATE POLICY "メンバーの追加"
  ON chat_room_members
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- メンバーの削除ポリシー
CREATE POLICY "メンバーの削除"
  ON chat_room_members
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid() OR 
    EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE id = room_id
      AND created_by = auth.uid()
    )
  );