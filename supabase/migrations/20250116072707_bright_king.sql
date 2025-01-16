/*
  # AI Chat機能の追加

  1. 変更内容
    - messagesテーブルにAI応答フラグとAI応答テキストを追加
    - AIメッセージ生成のための関数を追加

  2. セキュリティ
    - RLSポリシーは既存のものを継続使用
*/

-- メッセージテーブルの拡張
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS is_ai_response boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS ai_response text;

-- AIメッセージ生成関数
CREATE OR REPLACE FUNCTION generate_ai_response(message_text text)
RETURNS text AS $$
DECLARE
  responses text[] := ARRAY[
    'なるほど、興味深い視点ですね。',
    '確かにその通りですね。',
    'とても良い考えだと思います。',
    'それは素晴らしいアイデアですね。',
    'なるほど、そういう考え方もありますね。',
    '面白い観点からの意見ですね。',
    'その考えには説得力がありますね。',
    'とても参考になる意見です。',
    'そうですね、私もそう思います。',
    '新しい視点を提供していただき、ありがとうございます。'
  ];
BEGIN
  RETURN responses[1 + floor(random() * array_length(responses, 1))];
END;
$$ LANGUAGE plpgsql;