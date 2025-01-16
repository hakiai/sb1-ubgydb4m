/*
  # チャットルームメンバーのRLSポリシーを修正

  1. Changes
    - チャットルームメンバーのRLSポリシーを単純化
    - 無限再帰を防ぐ
*/

-- チャットルームメンバーのRLSポリシーを更新
DROP POLICY IF EXISTS "メンバーの参照" ON chat_room_members;
DROP POLICY IF EXISTS "メンバーの追加" ON chat_room_members;

-- シンプルな参照ポリシー
CREATE POLICY "メンバーの参照"
  ON chat_room_members
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- シンプルな追加ポリシー
CREATE POLICY "メンバーの追加"
  ON chat_room_members
  FOR INSERT
  TO authenticated
  WITH CHECK (true);