import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ARB 템플릿의 모든 키는 description 을 가진다', () {
    // gen-l10n 템플릿은 app_ko.arb 하나다. `@key` 메타데이터는 템플릿에만 두는
    // 것이 이 프로젝트의 규칙이라, app_en.arb·app_ja.arb 는 검사하지 않는다.
    final template = File('../../packages/l10n/lib/l10n/app_ko.arb');
    final arb = jsonDecode(template.readAsStringSync()) as Map<String, dynamic>;

    final messageKeys = arb.keys.where((key) => !key.startsWith('@')).toList();
    // 스캔이 0건이면 통과해도 아무것도 지키지 못한다.
    expect(
      messageKeys,
      isNotEmpty,
      reason: '${template.path}: 메시지 키를 하나도 찾지 못했습니다. 템플릿 경로나 형식이 바뀐 것입니다.',
    );

    final missing = messageKeys.where((key) {
      final meta = arb['@$key'];
      if (meta is! Map<String, dynamic>) return true;
      final description = meta['description'];
      return description is! String || description.trim().isEmpty;
    }).toList();

    expect(
      missing,
      isEmpty,
      reason:
          '${template.path}: description 이 없는 키 ${missing.length}개 — ${missing.join(', ')}\n'
          'description 은 번역자가 그 문구의 쓰임새를 아는 유일한 단서다. 특히 failure* 키는 '
          '어떤 도메인 오류에 붙는지 모르면 en·ja 로 옮길 수 없어, 뜻이 어긋난 번역이 그대로 나간다.',
    );
  });
}
