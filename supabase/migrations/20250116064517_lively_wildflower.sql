/*
  # Add friends feature

  1. New Tables
    - `friendships`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `friend_id` (uuid, references auth.users)
      - `created_at` (timestamptz)
      - `status` (text) - 'pending' or 'accepted'

  2. Security
    - Enable RLS on `friendships` table
    - Add policies for friend management
*/

-- フレンドシップテーブルの作成
CREATE TABLE IF NOT EXISTS friendships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  friend_id uuid REFERENCES auth.users(id) NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'accepted')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, friend_id)
);

-- RLSの有効化
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- フレンドシップのポリシー
CREATE POLICY "ユーザーは自分のフレンドシップを参照できる"
  ON friendships
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR friend_id = auth.uid());

CREATE POLICY "ユーザーはフレンドリクエストを送信できる"
  ON friendships
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "ユーザーは自分のフレンドシップを更新できる"
  ON friendships
  FOR UPDATE
  TO authenticated
  USING (friend_id = auth.uid())
  WITH CHECK (friend_id = auth.uid());