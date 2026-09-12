import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageStorage.objectPathFromPublicUrl', () {
    const base = 'https://x.supabase.co/storage/v1/object/public/avatars';

    test('공개 URL 에서 버킷 내부 경로를 뽑는다', () {
      expect(
        ImageStorage.objectPathFromPublicUrl(
          bucket: 'avatars',
          publicUrl: '$base/u1/1700000000.webp',
        ),
        'u1/1700000000.webp',
      );
    });

    test('쿼리 문자열은 떼어낸다', () {
      expect(
        ImageStorage.objectPathFromPublicUrl(
          bucket: 'avatars',
          publicUrl: '$base/u1/1700000000.jpg?width=100',
        ),
        'u1/1700000000.jpg',
      );
    });

    test('퍼센트 인코딩을 되돌린다', () {
      expect(
        ImageStorage.objectPathFromPublicUrl(
          bucket: 'avatars',
          publicUrl: '$base/u1/my%20photo.jpg',
        ),
        'u1/my photo.jpg',
      );
    });

    test('다른 버킷이나 외부 URL 이면 null 이다', () {
      // 우리가 올린 적 없는 이미지를 지우려 들면 안 된다.
      expect(
        ImageStorage.objectPathFromPublicUrl(
          bucket: 'avatars',
          publicUrl:
              'https://x.supabase.co/storage/v1/object/public/posts/u1/a.webp',
        ),
        isNull,
      );
      expect(
        ImageStorage.objectPathFromPublicUrl(
          bucket: 'avatars',
          publicUrl: 'https://example.com/a.png',
        ),
        isNull,
      );
    });

    test('URL 이 없으면 null 이다', () {
      expect(
        ImageStorage.objectPathFromPublicUrl(
          bucket: 'avatars',
          publicUrl: null,
        ),
        isNull,
      );
    });
  });
}
