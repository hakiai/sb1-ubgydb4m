/*
  # Fix friendship schema and relationships

  1. Changes
    - Drop and recreate friendships table with correct foreign key relationships
    - Update RLS policies
    - Add explicit foreign key relationships to profiles

  2. Security
    - Enable RLS
    - Add policies for SELECT, INSERT, and UPDATE operations
*/

-- Drop existing friendships table and recreate with correct relationships
DROP TABLE IF EXISTS friendships CASCADE;

CREATE TABLE friendships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  friend_id uuid NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'accepted')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, friend_id),
  FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (friend_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Policies for friendships table
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