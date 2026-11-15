import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/draft/draft_context.dart';
import 'package:walk/domain/diary/draft/draft_length.dart';
import 'package:walk/domain/diary/draft/draft_prompt.dart';
import 'package:walk/domain/diary/draft/draft_style.dart';

DraftContext _full() => DraftContext(
  memo: '  성수동 카페에서 독서  ',
  occurredAt: DateTime(2026, 11, 15, 14, 30),
  placeName: '성수동',
  photoCount: 3,
  videoCount: 1,
  photoTakenFrom: DateTime(2026, 11, 15, 13, 5),
  photoTakenTo: DateTime(2026, 11, 15, 15, 20),
  tags: const ['카페', '독서'],
);

DraftContext _bare({String memo = ''}) =>
    DraftContext(memo: memo, occurredAt: DateTime(2026, 11, 15, 9));

void main() {
  group('user', () {
    test('메모와 맥락 줄을 모두 싣는다', () {
      final text = DraftPrompt.user(_full());

      expect(text, contains('메모: 성수동 카페에서 독서\n'));
      expect(text, contains('기록 시각: 2026-11-15 14:30'));
      expect(text, contains('장소: 성수동'));
      expect(text, contains('사진 3장 · 영상 1개'));
      expect(text, contains('사진 촬영 시각: 2026-11-15 13:05 ~ 15:20'));
      expect(text, contains('태그: 카페, 독서'));
    });

    test('빈 값은 줄째 뺀다(기록 시각은 늘 있다)', () {
      final text = DraftPrompt.user(_bare());

      expect(text, contains('기록 시각: 2026-11-15 09:00'));
      for (final label in ['메모:', '장소:', '사진', '영상', '태그:']) {
        expect(text, isNot(contains(label)), reason: label);
      }
    });

    test('공백뿐인 장소 · 태그도 뺀다', () {
      final text = DraftPrompt.user(
        DraftContext(
          memo: '   ',
          occurredAt: DateTime(2026, 11, 15, 9),
          placeName: '  ',
          tags: const [''],
        ),
      );

      for (final label in ['메모:', '장소:', '태그:']) {
        expect(text, isNot(contains(label)), reason: label);
      }
    });

    test('사진만 · 영상만이면 그것만 센다', () {
      expect(
        DraftPrompt.user(
          DraftContext(memo: 'a', occurredAt: DateTime(2026), photoCount: 2),
        ),
        contains('사진 2장\n'),
      );
      final videoOnly = DraftPrompt.user(
        DraftContext(memo: 'a', occurredAt: DateTime(2026), videoCount: 1),
      );
      expect(videoOnly, contains('영상 1개'));
      expect(videoOnly, isNot(contains('사진')));
    });

    test('촬영 시각이 하나면 범위 없이, 날이 다르면 날짜를 둘 다', () {
      final one = DraftPrompt.user(
        DraftContext(
          memo: 'a',
          occurredAt: DateTime(2026),
          photoCount: 1,
          photoTakenFrom: DateTime(2026, 11, 15, 13, 5),
          photoTakenTo: DateTime(2026, 11, 15, 13, 5),
        ),
      );
      final twoDays = DraftPrompt.user(
        DraftContext(
          memo: 'a',
          occurredAt: DateTime(2026),
          photoCount: 2,
          photoTakenFrom: DateTime(2026, 11, 14, 20),
          photoTakenTo: DateTime(2026, 11, 15, 9),
        ),
      );

      expect(one, contains('사진 촬영 시각: 2026-11-15 13:05\n'));
      expect(
        twoDays,
        contains('사진 촬영 시각: 2026-11-14 20:00 ~ 2026-11-15 09:00'),
      );
    });

    test('좌표처럼 보이는 숫자는 없다', () {
      final text = DraftPrompt.user(_full());

      expect(text, isNot(matches(RegExp(r'\d+\.\d{3,}'))));
      expect(text.toLowerCase(), isNot(contains('lat')));
    });
  });

  group('system', () {
    test('공통 지시: 1인칭 개인 일기 · 지어내지 않기 · 글만', () {
      final text = DraftPrompt.system(
        style: DraftStyle.diary,
        length: DraftLength.normal,
      );

      expect(text, contains('1인칭'));
      expect(text, contains('일기'));
      expect(text, contains('지어내지'));
      expect(text, contains('글만 돌려준다'));
    });

    test('목표 문장 수를 숫자로 싣는다', () {
      expect(
        DraftPrompt.system(style: DraftStyle.diary, length: DraftLength.short),
        contains('1~2문장'),
      );
      expect(
        DraftPrompt.system(style: DraftStyle.diary, length: DraftLength.long),
        contains('3~6문장'),
      );
    });

    test('긴 메모면 덧붙이지 말고 다듬으라고 한다', () {
      final polish = DraftPrompt.system(
        style: DraftStyle.diary,
        length: const DraftLength(min: 3, max: 6, polishMemo: true),
      );
      final plain = DraftPrompt.system(
        style: DraftStyle.diary,
        length: DraftLength.long,
      );

      expect(polish, contains('다듬'));
      expect(plain, isNot(contains('다듬')));
    });

    test('문체마다 그 지시를 싣는다', () {
      for (final style in DraftStyle.values) {
        final text = DraftPrompt.system(
          style: style,
          length: DraftLength.normal,
        );
        expect(text, contains(style.instruction), reason: style.name);
        for (final other in DraftStyle.values.where((s) => s != style)) {
          expect(text, isNot(contains(other.instruction)), reason: other.name);
        }
      }
    });

    test('문체 지시 요지', () {
      expect(DraftStyle.diary.instruction, contains('했다'));
      expect(DraftStyle.polite.instruction, contains('했어요'));
      expect(DraftStyle.sns.instruction, contains('이모지는 1~2개'));
      expect(DraftStyle.memo.instruction, contains('함'));
      for (final style in DraftStyle.values) {
        expect(style.instruction, contains('해시태그'), reason: style.name);
      }
    });

    test('기본 문체는 일기체', () {
      expect(DraftStyle.fallback, DraftStyle.diary);
    });

    test('사진을 붙이면 사진에 보이는 것만 쓰라고 한다', () {
      final withPhotos = DraftPrompt.system(
        style: DraftStyle.diary,
        length: DraftLength.normal,
        withPhotos: true,
      );
      final without = DraftPrompt.system(
        style: DraftStyle.diary,
        length: DraftLength.normal,
      );

      expect(withPhotos, contains('붙인 사진'));
      expect(without, isNot(contains('붙인 사진')));
    });
  });
}
