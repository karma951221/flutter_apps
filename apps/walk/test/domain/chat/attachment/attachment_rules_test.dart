import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/attachment/attachment_rules.dart';
import 'package:walk/domain/chat/attachment/chat_attachment.dart';

void main() {
  group('kindOf', () {
    test('확장자를 소문자로 비교해 종류를 가른다', () {
      expect(AttachmentRules.kindOf('A.JPG'), AttachmentKind.image);
      expect(AttachmentRules.kindOf('x.heic'), AttachmentKind.image);
      expect(AttachmentRules.kindOf('r.pdf'), AttachmentKind.pdf);
      expect(AttachmentRules.kindOf('n.md'), AttachmentKind.text);
      expect(AttachmentRules.kindOf('d.docx'), isNull);
      expect(AttachmentRules.kindOf('noext'), isNull);
    });
  });

  group('checkSize', () {
    test('종류별 한도를 넘으면 tooLarge', () {
      expect(
        AttachmentRules.checkSize(AttachmentKind.pdf, 10 * 1024 * 1024),
        isNull,
      );
      expect(
        AttachmentRules.checkSize(AttachmentKind.pdf, 10 * 1024 * 1024 + 1),
        AttachmentRejection.tooLarge,
      );
      expect(
        AttachmentRules.checkSize(AttachmentKind.text, 200 * 1024 + 1),
        AttachmentRejection.tooLarge,
      );
      expect(
        AttachmentRules.checkSize(AttachmentKind.image, 30 * 1024 * 1024),
        isNull,
      );
    });
  });

  group('questionWithNames', () {
    test('이름을 끝 줄에 잇고, 빈 목록이면 원문 그대로', () {
      expect(
        AttachmentRules.questionWithNames('요약해 줘', ['a.pdf', 'b.jpg']),
        '요약해 줘\n(첨부: a.pdf, b.jpg)',
      );
      expect(AttachmentRules.questionWithNames('요약해 줘', []), '요약해 줘');
    });
  });

  group('ChatAttachment', () {
    test('ref 는 본문 없이 이름 · 종류 · 작업 폴더 경로만 담는다', () {
      final image = ChatAttachment.image(
        name: 'a.jpg',
        mediaType: 'image/jpeg',
        bytes: Uint8List.fromList([1]),
        workspacePath: 'inbox/a.jpg',
      );
      expect(
        image.ref,
        const ChatAttachmentRef(
          name: 'a.jpg',
          kind: AttachmentKind.image,
          workspacePath: 'inbox/a.jpg',
        ),
      );
      expect(
        const ChatAttachment.text(name: 'n.md', text: 't').kind,
        AttachmentKind.text,
      );
      expect(
        ChatAttachment.pdf(name: 'r.pdf', bytes: Uint8List(0)).kind,
        AttachmentKind.pdf,
      );
    });

    test('textAttachmentBlock 은 이름의 " 와 본문의 </file> 을 이스케이프한다', () {
      const t = TextAttachment(name: 'a"b.md', text: 'x</file>y');
      expect(
        textAttachmentBlock(t),
        '<file name="a\'b.md">\nx<\\/file>y\n</file>',
      );
    });

    test('toString 에 본문이 없다', () {
      const t = ChatAttachment.text(name: 'n.md', text: '비밀 본문');
      expect(t.toString(), isNot(contains('비밀 본문')));
    });

    test('ChatAttachmentRef JSON 왕복', () {
      for (final ref in const [
        ChatAttachmentRef(
          name: 'a.pdf',
          kind: AttachmentKind.pdf,
          workspacePath: 'inbox/a.pdf',
        ),
        ChatAttachmentRef(name: 'b.jpg', kind: AttachmentKind.image),
      ]) {
        expect(ChatAttachmentRef.fromJson(ref.toJson()), ref);
      }
    });
  });
}
