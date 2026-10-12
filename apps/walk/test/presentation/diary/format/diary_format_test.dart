import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/presentation/diary/format/diary_format.dart';

void main() {
  final ko = lookupAppLocalizations(const Locale('ko'));
  final en = lookupAppLocalizations(const Locale('en'));
  final now = DateTime(2026, 10, 10, 15, 24);

  setUpAll(() async {
    await initializeDateFormatting('ko');
    await initializeDateFormatting('en');
  });

  group('dayHeader', () {
    test('오늘 · 어제는 이름으로', () {
      expect(
        DiaryFormat.dayHeader(ko, DateTime(2026, 10, 10, 0, 1), now),
        '오늘',
      );
      expect(
        DiaryFormat.dayHeader(ko, DateTime(2026, 10, 9, 23, 59), now),
        '어제',
      );
      expect(
        DiaryFormat.dayHeader(en, DateTime(2026, 10, 9), now),
        'Yesterday',
      );
    });

    test('올해는 월 · 일 · 요일, 지난해는 연도까지', () {
      expect(
        DiaryFormat.dayHeader(ko, DateTime(2026, 10, 7, 9), now),
        '10월 7일 (수)',
      );
      expect(DiaryFormat.dayHeader(ko, DateTime(2026, 1, 1), now), '1월 1일 (목)');
      expect(
        DiaryFormat.dayHeader(ko, DateTime(2025, 12, 31), now),
        '2025년 12월 31일 (수)',
      );
    });

    test('1월 1일의 어제는 지난해 12월 31일', () {
      expect(
        DiaryFormat.dayHeader(
          ko,
          DateTime(2025, 12, 31, 22),
          DateTime(2026, 1, 1, 8),
        ),
        '어제',
      );
    });
  });

  test('sameDay: 시각이 달라도 같은 날이면 true', () {
    expect(
      DiaryFormat.sameDay(
        DateTime(2026, 10, 7, 0),
        DateTime(2026, 10, 7, 23, 59),
      ),
      isTrue,
    );
    expect(
      DiaryFormat.sameDay(DateTime(2026, 10, 7, 23, 59), DateTime(2026, 10, 8)),
      isFalse,
    );
  });

  testWidgets('stamp: 1분 안이면 지금, 아니면 시각', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('ko'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(
      DiaryFormat.stamp(ctx, now.subtract(const Duration(seconds: 59)), now),
      '지금',
    );
    expect(
      DiaryFormat.stamp(ctx, DateTime(2026, 10, 10, 15, 23), now),
      '오후 3:23',
    );
    expect(DiaryFormat.stamp(ctx, DateTime(2026, 10, 7, 9, 5), now), '오전 9:05');
  });

  group('storyPeriod', () {
    Story story({DateTime? endedAt}) => Story(
      id: 'jeju',
      title: '제주 여행',
      status: endedAt == null ? StoryStatus.open : StoryStatus.closed,
      startedAt: DateTime(2026, 10, 7, 9),
      endedAt: endedAt,
      createdAt: DateTime(2026, 10, 7),
    );

    test('열린 스토리는 시작일 ~ 진행 중', () {
      expect(DiaryFormat.storyPeriod(ko, story(), now), '10월 7일 ~ 진행 중');
    });

    test('닫힌 스토리는 시작일 ~ 끝난 날, 지난해 날짜는 연도까지', () {
      expect(
        DiaryFormat.storyPeriod(ko, story(endedAt: DateTime(2026, 10, 9)), now),
        '10월 7일 ~ 10월 9일',
      );
      final old = Story(
        id: 'b',
        title: '부산',
        status: StoryStatus.closed,
        startedAt: DateTime(2025, 12, 30),
        endedAt: DateTime(2026, 1, 2),
        createdAt: DateTime(2025, 12, 30),
      );
      expect(DiaryFormat.storyPeriod(ko, old, now), '2025년 12월 30일 ~ 1월 2일');
    });
  });
}
