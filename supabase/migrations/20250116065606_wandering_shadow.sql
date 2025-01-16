/*
  # プロフィール作成の修正

  1. 変更内容
    - トリガー関数の修正
    - プロフィールテーブルのインデックス追加
    - 既存のプロフィールデータのクリーンアップ

  2. セキュリティ
    - RLSポリシーの維持
*/

-- トリガー関数の更新
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  profile_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM profiles WHERE id = new.id
  ) INTO profile_exists;

  IF NOT profile_exists THEN
    INSERT INTO public.profiles (id, username, email)
    VALUES (
      new.id,
      COALESCE(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
      new.email
    );
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- インデックスの追加
CREATE INDEX IF NOT EXISTS profiles_email_idx ON profiles(email);

-- 重複プロフィールのクリーンアップ
DELETE FROM profiles p1 USING profiles p2
WHERE p1.id = p2.id
AND p1.ctid < p2.ctid;