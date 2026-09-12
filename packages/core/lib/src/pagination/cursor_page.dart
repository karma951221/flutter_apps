import 'package:freezed_annotation/freezed_annotation.dart';

part 'cursor_page.freezed.dart';

/// 커서 페이지네이션의 한 페이지.
///
/// [nextCursor] 는 다음 페이지를 요청할 때 그대로 돌려주는 **불투명 문자열**이다.
/// 내부 형식은 data 계층만 알고, domain 과 presentation 은 해석하지 않는다.
/// 이렇게 해두면 백엔드가 커서 표현을 바꿔도 바깥 계층이 영향을 받지 않는다.
@freezed
class CursorPage<T> with _$CursorPage<T> {
  const CursorPage({required this.items, this.nextCursor});

  @override
  final List<T> items;

  @override
  final String? nextCursor;

  /// 다음 페이지가 남아 있는지.
  bool get hasMore => nextCursor != null;
}
