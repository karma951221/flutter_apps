import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/entity/wiki_note.dart';

void main() {
  group('parseWikiBody', () {
    test('[[12]] 와 [[일기:a1-b2]] 를 링크로, 나머지는 글로 나눈다', () {
      final segments = parseWikiBody('앞 [[12]] 가운데 [[일기:a1-b2]] 끝');

      expect(segments, [
        const WikiSegment.text('앞 '),
        const WikiSegment.link(WikiLink.note(12), '[[12]]'),
        const WikiSegment.text(' 가운데 '),
        const WikiSegment.link(WikiLink.diary('a1-b2'), '[[일기:a1-b2]]'),
        const WikiSegment.text(' 끝'),
      ]);
    });

    test('[[abc]] · [[일기:]] · [[ 3 ]] 는 글로 둔다', () {
      const body = '[[abc]] [[일기:]] [[ 3 ]]';

      expect(parseWikiBody(body), [const WikiSegment.text(body)]);
      expect(wikiLinksIn(body), isEmpty);
    });

    test('빈 본문은 조각이 없다', () {
      expect(parseWikiBody(''), isEmpty);
    });

    test('링크만 있으면 링크 조각 하나', () {
      expect(parseWikiBody('[[7]]'), [
        const WikiSegment.link(WikiLink.note(7), '[[7]]'),
      ]);
    });
  });

  test('wikiLinksIn 은 순서대로 중복 없이', () {
    expect(wikiLinksIn('[[3]] [[일기:x]] [[3]] [[1]] [[일기:x]]'), [
      const WikiLink.note(3),
      const WikiLink.diary('x'),
      const WikiLink.note(1),
    ]);
  });

  test('stripWikiLinks 는 keep 이 false 인 링크만 지우고 공백을 정리한다', () {
    final out = stripWikiLinks(
      '처음 [[3]] 그리고 [[9]] 또 [[일기:d1]] 끝 [[9]]',
      (link) => link != const WikiLink.note(9),
    );

    expect(out, '처음 [[3]] 그리고 또 [[일기:d1]] 끝');
  });

  test('stripWikiLinks 는 줄바꿈을 건드리지 않는다', () {
    final out = stripWikiLinks('첫 줄 [[9]]\n둘째 줄', (_) => false);

    expect(out, '첫 줄\n둘째 줄');
  });

  test('지운 링크 뒤가 공백뿐이면 다음 조각과 공백 하나로 잇는다', () {
    bool drop9(WikiLink link) => link != const WikiLink.note(9);

    expect(stripWikiLinks('a [[9]] [[3]] b', drop9), 'a [[3]] b');
    expect(stripWikiLinks('a [[9]] \nb', drop9), 'a\nb');
    expect(stripWikiLinks('a [[9]][[9]] b', drop9), 'a b');
    expect(stripWikiLinks('a [[9]] [[9]] b', drop9), 'a b');
    expect(stripWikiLinks('[[9]] [[9]] a', drop9), 'a');
    expect(stripWikiLinks('a [[9]] [[9]] ', drop9), 'a');
  });

  test('[[일기:x[[3]] 의 일기 id 는 [ 를 품지 않아 [[3]] 이 링크로 남는다', () {
    expect(wikiLinksIn('[[일기:x[[3]]'), [const WikiLink.note(3)]);
  });

  test('앞자리가 0 인 [[012]] 는 글로 둔다 — [[0]] 은 링크', () {
    expect(wikiLinksIn('[[012]] [[00]]'), isEmpty);
    expect(wikiLinksIn('[[0]]'), [const WikiLink.note(0)]);
  });

  test('wikiNoteLinkText · wikiDiaryLinkText 를 parseWikiBody 가 되읽는다', () {
    expect(wikiNoteLinkText(12), '[[12]]');
    expect(wikiDiaryLinkText('abc'), '[[일기:abc]]');

    final body = '${wikiNoteLinkText(12)}${wikiDiaryLinkText('abc')}';
    expect(wikiLinksIn(body), [
      const WikiLink.note(12),
      const WikiLink.diary('abc'),
    ]);
  });

  test('상한 상수', () {
    expect(wikiTitleMax, 60);
    expect(wikiSummaryMax, 120);
    expect(wikiBodyMax, 4000);
  });

  group('toString 에 제목 · 요약 · 본문이 없다', () {
    const title = '비밀제목';
    const summary = '비밀요약';
    const body = '비밀본문 내용';

    void expectHidden(Object value) {
      final s = value.toString();
      expect(s, isNot(contains(title)));
      expect(s, isNot(contains(summary)));
      expect(s, isNot(contains(body)));
    }

    test('WikiNote', () {
      final note = WikiNote(
        id: 3,
        title: title,
        summary: summary,
        body: body,
        sourceConversationId: 'c1',
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );
      expectHidden(note);
      expect(
        note.toString(),
        'WikiNote(id: 3, titleLength: 4, bodyLength: ${body.length})',
      );
    });

    test('WikiNoteDraft', () {
      expectHidden(
        const WikiNoteDraft(title: title, summary: summary, body: body),
      );
    });

    test('WikiCandidate', () {
      expectHidden(
        const WikiCandidate.create(title: title, summary: summary, body: body),
      );
      final update = const WikiCandidate.update(
        id: 4,
        title: title,
        summary: summary,
        body: body,
      );
      expectHidden(update);
      expect(update.toString(), contains('id: 4'));
    });
  });
}
