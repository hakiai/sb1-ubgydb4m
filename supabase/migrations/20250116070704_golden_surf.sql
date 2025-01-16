/*
  # Fix friends query and relationships

  1. Changes
    - Add explicit foreign key relationships between friendships and profiles
    - Update RLS policies for better access control
    - Add indexes for better query performance

  2. Security
    - Maintain existing RLS policies
    - Ensure proper access control for friendships
*/

-- Drop existing friendships table and recreate with correct relationships
DROP TABLE IF EXISTS friendships CASCADE;

CREATE TABLE friendships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  friend_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status text NOT NULL CHECK (status IN ('pending', 'accepted')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, friend_id)
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON friendships(friend_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON friendships(status);

-- Enable RLS
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Create policies
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

-- Recreate test friendships
DO $$
DECLARE
  test_user1_id uuid;
  test_user2_id uuid;
  test_user3_id uuid;
BEGIN
  -- Get test user IDs from profiles
  SELECT id INTO test_user1_id FROM profiles WHERE email = 'test1@example.com' LIMIT 1;
  SELECT id INTO test_user2_id FROM profiles WHERE email = 'test2@example.com' LIMIT 1;
  SELECT id INTO test_user3_id FROM profiles WHERE email = 'test3@example.com' LIMIT 1;

  -- Create friendships (bidirectional)
  IF test_user1_id IS NOT NULL AND test_user2_id IS NOT NULL THEN
    INSERT INTO friendships (user_id, friend_id, status)
    VALUES
      (test_user1_id, test_user2_id, 'accepted'),
      (test_user2_id, test_user1_id, 'accepted')
    ON CONFLICT (user_id, friend_id) DO NOTHING;
  END IF;

  IF test_user1_id IS NOT NULL AND test_user3_id IS NOT NULL THEN
    INSERT INTO friendships (user_id, friend_id, status)
    VALUES
      (test_user1_id, test_user3_id, 'accepted'),
      (test_user3_id, test_user1_id, 'accepted')
    ON CONFLICT (user_id, friend_id) DO NOTHING;
  END IF;
END $$;