import 'dart:io';

/// 손으로 만든 벤더 응답 픽스처(`test/fixtures/chat/` 기준 경로) → 다시 녹화할
/// 확인 항목 번호(계획 "구현 전 확인"). 실제 응답으로 바꾸면 키 · 계정 id 를
/// 지우고 여기서 뺀다. SSE 픽스처는 첫 줄 주석에 같은 번호를 단다.
const Map<String, String> handMadeFixtures = {
  'anthropic/models_page1.json': 'A1',
  'anthropic/models_page2.json': 'A1',
  'openai/models.json': 'O4',
  'openai/error_insufficient_quota.json': 'O6',
  'openai/error_rate_limit.json': 'O6',
  'openai/error_invalid_key.json': 'O6',
  'openai/error_model_not_found.json': 'O6',
  'openai/error_image.json': 'O6',
};

/// `test/fixtures/chat/<path>` 의 글.
String chatFixture(String path) =>
    File('test/fixtures/chat/$path').readAsStringSync();
