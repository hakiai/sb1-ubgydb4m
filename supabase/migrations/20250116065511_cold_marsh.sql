/*
  # プロフィールトリガーの修正

  1. 変更内容
    - 新規ユーザー登録時のプロフィール作成トリガーを修正
    - トリガー関数の更新

  2. セキュリティ
    - 既存のRLSポリシーを維持
    - トリガー関数のセキュリティ設定を確認
*/

-- 新規ユーザー登録時のトリガー関数を更新
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, username)
  VALUES (new.id, COALESCE(new.raw_user_meta_data->>'username', new.email))
  ON CONFLICT (id) DO UPDATE
  SET username = EXCLUDED.username,
      updated_at = now();
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 既存のトリガーを削除して再作成
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();