import 'dart:typed_data';

import '../error/failure.dart';

/// 이미지 객체 저장소의 계약.
///
/// 경로의 첫 조각은 항상 로그인한 사용자의 id 다 — 구현체가 세션에서 읽어
/// 붙이므로 호출부는 사용자 id 를 알 필요가 없고, Storage RLS 와 같은 규칙이
/// 한 곳에만 남는다.
///
/// 이 계약에는 백엔드 SDK 타입이 없다. 실패는 앱의 [Failure] 로 던지므로
/// (규칙 ①·④) 호출부가 `StorageException` 같은 SDK 예외를 보지 않는다.
abstract interface class ImageStorage {
  /// 이미지를 올리고 공개 URL 을 돌려준다.
  ///
  /// 경로는 `{userId}/[folder/]{name}.{extension}` 이 된다. [folder] 는 한
  /// 게시물의 이미지들처럼 여러 객체를 묶을 때, [name] 은 순번처럼 이름을
  /// 호출부가 정해야 할 때 쓴다. [name] 을 생략하면 구현체가 충돌하지 않는
  /// 이름을 만든다.
  ///
  /// [contentType] 과 [extension] 을 함께 받는 이유는 인코딩 형식이 플랫폼마다
  /// 다르기 때문이다 (Android WebP, 그 밖 JPEG).
  ///
  /// 실패하면 [Failure] 를 던진다.
  Future<String> upload({
    required String bucket,
    required Uint8List bytes,
    required String contentType,
    required String extension,
    String? folder,
    String? name,
  });

  /// 공개 URL 이 가리키는 객체를 지운다. 실패는 삼킨다.
  ///
  /// 교체된 옛 이미지나 저장에 실패한 새 이미지를 치우는 용도라, 여기서 난
  /// 오류로 호출부의 저장 흐름을 되돌리지 않는다.
  Future<void> removeByPublicUrl({
    required String bucket,
    required String? publicUrl,
  });

  /// 버킷 안의 객체들을 한 번에 지운다. [removeByPublicUrl] 과 같이 best-effort 다.
  Future<void> removePaths({
    required String bucket,
    required List<String> paths,
  });

  /// 버킷에서 **로그인한 사용자의 경로 전체**를 지운다. best-effort 다.
  ///
  /// 회원 탈퇴가 쓴다. DB 의 delete_account() 는 storage.objects 를 지울 수
  /// 없으므로(Storage 확장의 보호 트리거) 객체 정리는 앱의 몫이고, 실패해도
  /// 탈퇴 흐름을 막지 않는다.
  Future<void> removeAllForCurrentUser({required String bucket});

  /// 공개 URL 에서 버킷 안의 객체 경로를 뽑는다.
  ///
  /// 다른 버킷이나 외부 URL 이면 null 을 준다. 우리가 올린 적 없는 이미지를
  /// 지우려 들면 안 되기 때문이다. 순수 문자열 처리라 구현체 없이도 쓸 수 있게
  /// static 으로 둔다.
  static String? objectPathFromPublicUrl({
    required String bucket,
    required String? publicUrl,
  }) {
    if (publicUrl == null) return null;
    final marker = '/object/public/$bucket/';
    final index = publicUrl.indexOf(marker);
    if (index < 0) return null;

    var path = publicUrl.substring(index + marker.length);
    final query = path.indexOf('?');
    if (query >= 0) path = path.substring(0, query);
    if (path.isEmpty) return null;

    return Uri.decodeComponent(path);
  }
}
