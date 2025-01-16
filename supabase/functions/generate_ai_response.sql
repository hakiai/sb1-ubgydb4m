create or replace function generate_ai_response(
  message_text text,
  conversation_history jsonb default '[]',
  chat_context jsonb default '{}'
) returns text language plpgsql security definer as $$
declare
  response text;
  api_key text;
  api_response json;
begin
  -- OpenAI APIキーを環境変数から取得
  api_key := current_setting('app.settings.openai_api_key', true);

  -- OpenAI APIを呼び出し
  select content into response
  from http((
    'POST',
    'https://api.openai.com/v1/chat/completions',
    ARRAY[
      ('Authorization', 'Bearer ' || api_key),
      ('Content-Type', 'application/json')
    ],
    'application/json',
    json_build_object(
      'model', 'gpt-3.5-turbo',
      'messages', conversation_history || json_build_array(
        json_build_object(
          'role', 'system',
          'content', 'あなたはフレンドリーで役立つAIアシスタントです。'
        ),
        json_build_object(
          'role', 'user',
          'content', message_text
        )
      ),
      'temperature', 0.7
    )::text
  ))::json -> 'choices' -> 0 -> 'message' -> 'content';

  return response;
end;
$$; 