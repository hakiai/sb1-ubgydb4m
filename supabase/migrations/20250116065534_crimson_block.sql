/*
  # プロフィールテーブルの修正

  1. 変更内容
    - プロフィールテーブルの構造を更新
    - トリガー関数の修正
    - 既存のプロフィールデータの更新

  2. セキュリティ
    - RLSポリシーの維持
*/

-- プロフィールテーブルの更新
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS email text;

-- トリガー関数の更新
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, username, email)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'username', new.email),
    new.email
  )
  ON CONFLICT (id) DO UPDATE
  SET 
    username = EXCLUDED.username,
    email = EXCLUDED.email,
    updated_at = now();
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 既存のプロフィールを更新
DO $$
BEGIN
  UPDATE profiles p
  SET email = u.email
  FROM auth.users u
  WHERE p.id = u.id
  AND p.email IS NULL;
END $$;