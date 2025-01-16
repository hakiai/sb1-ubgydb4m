/*
  # チャットメッセージテーブルの作成

  1. 新規テーブル
    - `messages`
      - `id` (uuid, プライマリーキー)
      - `text` (text, メッセージ内容)
      - `is_sent` (boolean, 送信済みフラグ)
      - `created_at` (timestamp, 作成日時)
      - `user_id` (uuid, ユーザーID)

  2. セキュリティ
    - RLSを有効化
    - 認証済みユーザーのみ読み書き可能
*/

CREATE TABLE messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  text text NOT NULL,
  is_sent boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  user_id uuid NOT NULL REFERENCES auth.users(id)
);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ユーザーは自分のメッセージを読み取れる"
  ON messages
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "ユーザーは新しいメッセージを作成できる"
  ON messages
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);