/*
  # 認証システムのセットアップ

  1. 変更内容
    - プロフィールテーブルの作成
    - RLSポリシーの設定
  
  2. セキュリティ
    - プロフィールテーブルのRLS有効化
    - 認証ユーザーのみ自身のプロフィールにアクセス可能
*/

-- プロフィールテーブルの作成
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  username text,
  avatar_url text,
  updated_at timestamptz DEFAULT now()
);

-- RLSの有効化
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- プロフィール参照のポリシー
CREATE POLICY "ユーザーは自分のプロフィールを参照できる"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- プロフィール更新のポリシー
CREATE POLICY "ユーザーは自分のプロフィールを更新できる"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- プロフィール作成のポリシー
CREATE POLICY "ユーザーは自分のプロフィールを作成できる"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- 新規ユーザー登録時に自動的にプロフィールを作成
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id)
  VALUES (new.id);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- トリガーの作成
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();