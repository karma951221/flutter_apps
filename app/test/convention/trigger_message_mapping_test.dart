import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 마이그레이션에는 남아 있지만 현재 스키마가 절대 던질 수 없는 문구.
///
/// `20260825120000_add_blocks.sql` 이 `enforce_comment_depth()` 를 이 문구로
/// 만들었고, 뒤이은 `20260825130000_neutral_block_message.sql` 이 같은 함수를
/// 방향 중립인 '이 게시물에는 댓글을 달 수 없습니다' 로 갈아끼웠다.
/// 마이그레이션은 append-only 라 옛 파일의 문구는 그대로 남지만, 최신 스키마에서
/// 이 문구를 던지는 경로는 없다. 그래서 mapper 도 알 필요가 없다.
///
/// 넓은 패턴이 아니라 이 문자열 하나만 적는다 — 새로 추가되는 차단 관련 문구가
/// 조용히 빠져나가면 안 된다.
const _supersededMessages = {'차단한 사용자의 게시물에는 댓글을 달 수 없습니다'};

void main() {
  test('트리거가 던지는 한국어 문구는 모두 SupabaseErrorMapper 가 안다', () {
    final migrationDirectory = Directory('../supabase/migrations');
    final migrations = migrationDirectory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.sql'))
        .toList();
    expect(
      migrations,
      isNotEmpty,
      reason: '${migrationDirectory.path}: 마이그레이션을 하나도 찾지 못했습니다. 경로가 바뀐 것입니다.',
    );

    // 트리거는 두 가지 형태로 문구를 던진다.
    //   raise exception '...'
    //   ... using message = '...'
    final raisePatterns = [
      RegExp(r"raise\s+exception\s+'((?:[^']|'')*)'", caseSensitive: false),
      RegExp(r"message\s*=\s*'((?:[^']|'')*)'", caseSensitive: false),
    ];
    final hangul = RegExp(r'[가-힣]');

    final messages = <String, String>{}; // 문구 → 처음 발견한 파일
    for (final migration in migrations) {
      final source = migration.readAsStringSync();
      for (final pattern in raisePatterns) {
        for (final match in pattern.allMatches(source)) {
          final message = match.group(1)!.replaceAll("''", "'");
          if (!hangul.hasMatch(message)) continue; // 영어 문구는 사용자에게 안 보인다.
          if (_supersededMessages.contains(message)) continue;
          messages.putIfAbsent(message, () => migration.path);
        }
      }
    }

    // 스캔이 0건이면 통과해도 아무것도 지키지 못한다.
    expect(
      messages,
      isNotEmpty,
      reason:
          '${migrationDirectory.path}: 한국어 raise 문구를 하나도 찾지 못했습니다. '
          'raise 형태가 바뀌었는지 확인하세요.',
    );

    // mapper 는 문구를 `static const` 맵(_commentDepthMessages ·
    // _reportTargetMessages · _blockMessages · _roomCapacityMessages)에 그대로
    // 담는다. 실행하지 않고 원문을 부분 문자열로 확인하는 것이 가장 튼튼하다.
    final mapper = File('lib/core/data/mapper/supabase_error_mapper.dart');
    final mapperSource = mapper.readAsStringSync();

    for (final entry in messages.entries) {
      expect(
        mapperSource.contains(entry.key),
        isTrue,
        reason:
            '${entry.value}: mapper 가 모르는 문구 \'${entry.key}\'\n'
            '${mapper.path} 의 문구 맵에 FailureCode 와 함께 등록하세요. 모르면 23514·23503 의 '
            '기본 문구("입력값이 조건을 만족하지 않습니다")로 덮여 원인이 사라지고, 매핑되지 않은 '
            '한국어 원문이 en·ja 사용자에게 그대로 샌다.',
      );
    }
  });
}
