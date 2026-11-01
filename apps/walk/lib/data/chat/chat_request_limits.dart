/// 한 응답의 최대 출력 토큰(Anthropic `max_tokens` · OpenAI `max_output_tokens`).
/// 벤더마다 같은 값을 쓴다 — 바꾸면 두 어댑터가 함께 바뀐다.
const chatMaxOutputTokens = 16000;
