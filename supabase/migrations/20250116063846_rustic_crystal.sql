/*
  # チャットルーム機能の追加

  1. 新しいテーブル
    - `chat_rooms`
      - `id` (uuid, primary key)
      - `name` (text) - チャットルームの名前
      - `created_at` (timestamp) - 作成日時
      - `created_by` (uuid) - 作成者のID

    - `chat_room_members`
      - `room_id` (uuid) - チャットルームのID
      - `user_id` (uuid) - メンバーのユーザーID
      - `joined_at` (timestamp) - 参加日時

  2. 変更点
    - messagesテーブルにroom_idカラムを追加
    - 既存のメッセージを新しい構造に対応

  3. セキュリティ
    - 各テーブルにRLSポリシーを追加
    - メンバーのみがチャットルームにアクセス可能
*/

-- チャットルームテーブルの作成
CREATE TABLE IF NOT EXISTS chat_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) NOT NULL
);

-- チャットルームメンバーテーブルの作成
CREATE TABLE IF NOT EXISTS chat_room_members (
  room_id uuid REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at timestamptz DEFAULT now(),
  PRIMARY KEY (room_id, user_id)
);

-- メッセージテーブルにroom_idを追加
ALTER TABLE messages ADD COLUMN IF NOT EXISTS room_id uuid REFERENCES chat_rooms(id);

-- RLSの有効化
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_room_members ENABLE ROW LEVEL SECURITY;

-- チャットルームのポリシー
CREATE POLICY "ユーザーは参加しているチャットルームを参照できる"
  ON chat_rooms
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM chat_room_members
      WHERE room_id = chat_rooms.id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "ユーザーは新しいチャットルームを作成できる"
  ON chat_rooms
  FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

-- チャットルームメンバーのポリシー
CREATE POLICY "ユーザーは自分が参加しているチャットルームのメンバーを参照できる"
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

CREATE POLICY "ユーザーは新しいメンバーを追加できる"
  ON chat_room_members
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE id = room_id
      AND created_by = auth.uid()
    )
  );

-- メッセージのポリシーを更新
CREATE POLICY "ユーザーは参加しているチャットルームのメッセージを参照できる"
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

CREATE POLICY "ユーザーは参加しているチャットルームにメッセージを送信できる"
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