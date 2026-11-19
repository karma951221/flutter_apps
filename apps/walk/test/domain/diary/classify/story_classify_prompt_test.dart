import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/classify/story_classify_prompt.dart';
import 'package:walk/domain/diary/classify/story_pick.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/story.dart';

import '../../../support/diary_fixtures.dart';

Story _story(String id, String title) => Story(
  id: id,
  title: title,
  status: StoryStatus.open,
  startedAt: DateTime(2026, 10),
  createdAt: DateTime(2026, 10),
);

final _daily = _story(Story.dailyId, '');
final _jeju = _story('jeju', '제주 여행');
final _run = _story('run', 'Running');

final _candidates = [
  StoryCandidate(story: _jeju, samples: const ['협재 해변 산책', '  ']),
  StoryCandidate(story: _run),
  StoryCandidate(story: _daily),
];

StoryPick? _parse(String text) =>
    StoryClassifyPrompt.parse(text, _candidates, dailyTitle: '일상');

void main() {
  group('parse — 기존 스토리', () {
    test('목록에 있는 story_id 면 existing, 이유를 담는다', () {
      expect(
        _parse('{"story_id": "jeju", "reason": "제주 바다 이야기라서"}'),
        const StoryPick.existing(storyId: 'jeju', reason: '제주 바다 이야기라서'),
      );
    });

    test('기본 스토리 id 도 고를 수 있다', () {
      expect(
        _parse('{"story_id": "daily", "reason": "평범한 하루"}'),
        const StoryPick.existing(storyId: Story.dailyId, reason: '평범한 하루'),
      );
    });

    test('목록에 없는 story_id 는 null(만들어 낸 id)', () {
      expect(_parse('{"story_id": "tokyo", "reason": "?"}'), isNull);
    });

    test('코드 블록 · 앞뒤 말이 붙어도 JSON 을 찾는다', () {
      expect(
        _parse('답:\n```json\n{"story_id": "run", "reason": "달리기"}\n```\n끝'),
        const StoryPick.existing(storyId: 'run', reason: '달리기'),
      );
    });

    test('reason 이 없거나 문자열이 아니면 빈 이유', () {
      expect(
        _parse('{"story_id": "run"}'),
        const StoryPick.existing(storyId: 'run', reason: ''),
      );
      expect(
        _parse('{"story_id": "run", "reason": 3}'),
        const StoryPick.existing(storyId: 'run', reason: ''),
      );
    });

    test('이유는 공백을 한 칸으로 줄이고 maxReasonLength 로 자른다', () {
      final long = '가' * (StoryClassifyPrompt.maxReasonLength + 10);
      final pick = _parse('{"story_id": "run", "reason": "$long"}');
      expect(
        (pick! as StoryPickExisting).reason.length,
        StoryClassifyPrompt.maxReasonLength,
      );
      expect(
        _parse('{"story_id": "run", "reason": " 아침\\n  달리기 "}'),
        const StoryPick.existing(storyId: 'run', reason: '아침 달리기'),
      );
    });

    test('story_id 와 new_story 가 함께 오면 story_id 를 본다', () {
      expect(
        _parse('{"story_id": "jeju", "new_story": "도쿄", "reason": "r"}'),
        const StoryPick.existing(storyId: 'jeju', reason: 'r'),
      );
    });
  });

  group('parse — 새 스토리', () {
    test('new_story 면 create', () {
      expect(
        _parse('{"new_story": "도쿄 출장", "reason": "새 여행의 시작"}'),
        const StoryPick.create(title: '도쿄 출장', reason: '새 여행의 시작'),
      );
    });

    test('기존 스토리와 이름이 같으면(대소문자 · 공백 무시) 그 스토리로', () {
      expect(
        _parse('{"new_story": "  running ", "reason": "r"}'),
        const StoryPick.existing(storyId: 'run', reason: 'r'),
      );
      expect(
        _parse('{"new_story": "일상", "reason": "r"}'),
        const StoryPick.existing(storyId: Story.dailyId, reason: 'r'),
      );
    });

    test('이름은 maxTitleLength 글자로 자른다(이모지를 반으로 자르지 않는다)', () {
      final name = '🏃' * (StoryClassifyPrompt.maxTitleLength + 5);
      final pick = _parse('{"new_story": "$name", "reason": ""}');
      expect(
        (pick! as StoryPickCreate).title.runes.length,
        StoryClassifyPrompt.maxTitleLength,
      );
    });

    test('빈 이름 · 문자열이 아닌 이름은 null', () {
      expect(_parse('{"new_story": "   ", "reason": "r"}'), isNull);
      expect(_parse('{"new_story": 1, "reason": "r"}'), isNull);
    });
  });

  group('parse — 잘못된 답', () {
    test('JSON 이 아니면 null', () {
      expect(_parse('제주 여행이 어울려요'), isNull);
      expect(_parse('{story_id: jeju}'), isNull);
      expect(_parse(''), isNull);
      expect(_parse('} {'), isNull);
    });

    test('객체가 아니거나 두 키가 다 없으면 null', () {
      expect(_parse('["jeju"]'), isNull);
      expect(_parse('{"reason": "r"}'), isNull);
      expect(_parse('{"story_id": "", "reason": "r"}'), isNull);
    });
  });

  group('user', () {
    test('스토리 id · 이름 · 최근 기록과 새 일기의 시각 · 장소 · 태그 · 본문을 싣는다', () {
      final text = StoryClassifyPrompt.user(
        entryDraft(
          body: '오늘 첫 출근',
          occurredAt: DateTime(2026, 11, 19, 8, 30),
          location: const EntryLocation(placeName: '판교'),
          tags: const ['회사'],
        ),
        _candidates,
        dailyTitle: '일상',
      );

      expect(text, contains('id: jeju | 이름: 제주 여행'));
      expect(text, contains('· 협재 해변 산책'));
      expect(text, contains('id: daily | 이름: 일상 (기본)'));
      expect(text, contains('시각: 2026-11-19 08:30'));
      expect(text, contains('장소: 판교'));
      expect(text, contains('태그: #회사'));
      expect(text, contains('오늘 첫 출근'));
      // 빈 최근 기록은 줄을 만들지 않는다.
      expect(text, isNot(contains('·  ')));
    });

    test('최근 기록과 본문을 자른다', () {
      final text = StoryClassifyPrompt.user(
        entryDraft(body: '나' * (StoryClassifyPrompt.maxBodyLength + 50)),
        [
          StoryCandidate(
            story: _jeju,
            samples: ['다' * (StoryClassifyPrompt.maxSampleLength + 50)],
          ),
        ],
        dailyTitle: '일상',
      );

      expect(
        RegExp('나+').firstMatch(text)!.group(0)!.length,
        StoryClassifyPrompt.maxBodyLength,
      );
      expect(
        RegExp('다+').firstMatch(text)!.group(0)!.length,
        StoryClassifyPrompt.maxSampleLength,
      );
    });
  });

  test('system 은 JSON 두 모양과 언어를 알린다', () {
    final ko = StoryClassifyPrompt.system('ko');
    expect(ko, contains('"story_id"'));
    expect(ko, contains('"new_story"'));
    expect(ko, contains('한국어'));
    expect(StoryClassifyPrompt.system('en'), contains('English'));
  });
}
