import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/chat/prefs_chat_model_catalog.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

Future<PrefsChatModelCatalog> _catalog([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return PrefsChatModelCatalog(await SharedPreferences.getInstance());
}

Future<PrefsChatModelCatalog> _reopen() async =>
    PrefsChatModelCatalog(await SharedPreferences.getInstance());

ModelInfo _m(String id, int day, {bool? tools, bool? images}) => ModelInfo(
  id: id,
  displayName: id.toUpperCase(),
  createdAt: DateTime.utc(2026, 1, day),
  supportsTools: tools,
  supportsImages: images,
);

final _at = DateTime.utc(2026, 11, 1, 9);

void main() {
  test('처음엔 비어 있다', () async {
    final catalog = await _catalog();

    expect(catalog.vendor, isNull);
    expect(catalog.models, isEmpty);
    expect(catalog.fetchedAt, isNull);
    expect(catalog.recommended, isNull);
  });

  test('replace 는 거른 목록을 최신순으로 저장하고 다시 읽어도 같다', () async {
    final catalog = await _catalog();

    await catalog.replace(ChatVendor.anthropic, [
      _m('claude-haiku-9-1', 1),
      _m('not-a-claude', 9),
      _m('claude-sonnet-9-9', 3, tools: true, images: false),
      _m('claude-opus-9-2', 2),
    ], _at);

    final ids = ['claude-sonnet-9-9', 'claude-opus-9-2', 'claude-haiku-9-1'];
    expect(catalog.models.map((m) => m.id), ids);

    final reader = await _reopen();
    expect(reader.vendor, ChatVendor.anthropic);
    expect(reader.models, catalog.models);
    expect(reader.models.first.displayName, 'CLAUDE-SONNET-9-9');
    expect(reader.models.first.supportsTools, isTrue);
    expect(reader.models.first.supportsImages, isFalse);
    expect(reader.models.first.createdAt, DateTime.utc(2026, 1, 3));
    expect(reader.fetchedAt, _at);
  });

  test('처음 replace 면 모두 본 것 · NEW 없음', () async {
    final catalog = await _catalog();

    await catalog.replace(ChatVendor.anthropic, [
      _m('claude-sonnet-9-1', 1),
      _m('claude-opus-9-1', 2),
    ], _at);

    expect(catalog.isNew('claude-sonnet-9-1'), isFalse);
    expect(catalog.isNew('claude-opus-9-1'), isFalse);
    expect(catalog.hasUnseenNewer(null), isFalse);
  });

  test('다음 replace 에 새 id 는 NEW', () async {
    final catalog = await _catalog();
    await catalog.replace(ChatVendor.anthropic, [
      _m('claude-sonnet-9-1', 1),
    ], _at);

    await catalog.replace(ChatVendor.anthropic, [
      _m('claude-sonnet-9-1', 1),
      _m('claude-sonnet-9-2', 2),
    ], _at);

    expect(catalog.isNew('claude-sonnet-9-2'), isTrue);
    expect(catalog.isNew('claude-sonnet-9-1'), isFalse);
    expect((await _reopen()).isNew('claude-sonnet-9-2'), isTrue);
  });

  test('벤더가 바뀌면 다시 모두 본 것', () async {
    final catalog = await _catalog();
    await catalog.replace(ChatVendor.anthropic, [
      _m('claude-sonnet-9-1', 1),
    ], _at);

    await catalog.replace(ChatVendor.openai, [
      _m('gpt-9', 1),
      _m('gpt-9-mini', 2),
    ], _at);

    expect(catalog.vendor, ChatVendor.openai);
    expect(catalog.isNew('gpt-9'), isFalse);
    expect(catalog.isNew('gpt-9-mini'), isFalse);
  });

  test('hasUnseenNewer: 지금보다 늦게 만든 안 본 모델이 있을 때만', () async {
    final catalog = await _catalog();
    await catalog.replace(ChatVendor.anthropic, [
      _m('claude-sonnet-9-5', 5),
    ], _at);
    await catalog.replace(ChatVendor.anthropic, [
      _m('claude-sonnet-9-5', 5),
      _m('claude-haiku-9-1', 1), // 안 봤지만 더 오래됨
      _m('claude-opus-9-9', 9), // 안 봤고 더 새것
    ], _at);

    expect(catalog.hasUnseenNewer('claude-sonnet-9-5'), isTrue);
    expect(catalog.hasUnseenNewer('claude-opus-9-9'), isFalse);
    // 지금 모델을 모르면(추천도 없는 등) 안 본 모델이 있는지만 본다.
    expect(catalog.hasUnseenNewer(null), isTrue);
  });

  test('markAllSeen 뒤 false', () async {
    final catalog = await _catalog();
    await catalog.replace(ChatVendor.anthropic, [
      _m('claude-sonnet-9-5', 5),
    ], _at);
    await catalog.replace(ChatVendor.anthropic, [
      _m('claude-sonnet-9-5', 5),
      _m('claude-opus-9-9', 9),
    ], _at);

    await catalog.markAllSeen();

    expect(catalog.hasUnseenNewer('claude-sonnet-9-5'), isFalse);
    expect(catalog.isNew('claude-opus-9-9'), isFalse);
    expect((await _reopen()).isNew('claude-opus-9-9'), isFalse);
  });

  test('recommended 는 recommendedModelOf 결과', () async {
    final catalog = await _catalog();
    await catalog.replace(ChatVendor.anthropic, [
      _m('claude-opus-9-9', 9),
      _m('claude-sonnet-9-5', 5),
      _m('claude-sonnet-9-1', 1),
    ], _at);

    expect(catalog.recommended, 'claude-sonnet-9-5');
  });

  test('find', () async {
    final catalog = await _catalog();
    await catalog.replace(ChatVendor.anthropic, [
      _m('claude-sonnet-9-5', 5),
    ], _at);

    expect(
      catalog.find('claude-sonnet-9-5')?.createdAt,
      DateTime.utc(2026, 1, 5),
    );
    expect(catalog.find('claude-none'), isNull);
  });

  test('markNoImages 는 replace 뒤에도 남는다', () async {
    final catalog = await _catalog();
    await catalog.replace(ChatVendor.openai, [_m('gpt-9', 1)], _at);

    await catalog.markNoImages('gpt-9');
    await catalog.replace(ChatVendor.openai, [_m('gpt-9', 1)], _at);

    expect(catalog.supportsImages('gpt-9'), isFalse);
    expect((await _reopen()).supportsImages('gpt-9'), isFalse);
  });

  test('supportsImages 는 표 · 기록을 함께 본다', () async {
    final catalog = await _catalog();
    await catalog.replace(ChatVendor.openai, [
      _m('gpt-9', 3),
      _m('gpt-9-turbo', 2, images: false),
      _m('gpt-3.5-turbo', 1),
    ], _at);

    expect(catalog.supportsImages('gpt-9'), isTrue);
    // 벤더가 알려 준 능력.
    expect(catalog.supportsImages('gpt-9-turbo'), isFalse);
    // 이미지 미지원 표.
    expect(catalog.supportsImages('gpt-3.5-turbo'), isFalse);

    await catalog.markNoImages('gpt-9');
    expect(catalog.supportsImages('gpt-9'), isFalse);
  });

  test('chat.models JSON 이 깨졌으면 빈 목록', () async {
    final catalog = await _catalog({
      'chat.models': '{not json',
      'chat.models.vendor': 'anthropic',
    });

    expect(catalog.models, isEmpty);
    expect(catalog.recommended, isNull);
    expect(catalog.find('x'), isNull);
  });

  test('chat.models 항목 모양이 어긋나면 그 항목만 건너뛴다', () async {
    final catalog = await _catalog({
      'chat.models':
          '[{"id":"claude-sonnet-9-1","name":"S","created":1},{"name":"no id"},3]',
      'chat.models.vendor': 'anthropic',
    });

    expect(catalog.models.map((m) => m.id), ['claude-sonnet-9-1']);
  });

  test('clear', () async {
    final catalog = await _catalog();
    await catalog.replace(ChatVendor.openai, [_m('gpt-9', 1)], _at);
    await catalog.markNoImages('gpt-9');

    await catalog.clear();

    final reader = await _reopen();
    for (final c in [catalog, reader]) {
      expect(c.vendor, isNull);
      expect(c.models, isEmpty);
      expect(c.fetchedAt, isNull);
      expect(c.recommended, isNull);
    }
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.startsWith('chat.models')), isEmpty);
  });
}
