import 'package:intl/intl.dart';

/// 목록에 찍는 날짜·시각 표기.
///
/// `post_tile` 과 `comment_tile` 이 각자 같은 자리맞춤 코드를 들고 있었다.
/// 출력 형식은 서로 다르다 — 게시물은 연도까지, 댓글은 최근 것이라 월·일부터
/// 보여준다 — 그래서 형식을 합치지 않고 자리맞춤만 한곳으로 모았다
/// (2026-08-27 리뷰).
extension DateTimeFormat on DateTime {
  /// 연도까지 보여준다. 게시물처럼 오래된 항목이 섞이는 목록에 쓴다.
  String displayDateTime(String localeName) {
    final d = toLocal();
    if (_languageCode(localeName) == 'ko') {
      // 기존 한국어 표기를 보존한다.
      return DateFormat('yyyy.MM.dd HH:mm', localeName).format(d);
    }
    return DateFormat.yMd(localeName).add_jm().format(d);
  }

  /// 연도를 생략한다. 댓글처럼 최근 항목만 보이는 목록에 쓴다.
  String displayShortDateTime(String localeName) {
    final d = toLocal();
    if (_languageCode(localeName) == 'ko') {
      return DateFormat('MM.dd HH:mm', localeName).format(d);
    }
    return DateFormat.Md(localeName).add_jm().format(d);
  }

  /// 날짜 없이 시각만. 대화 버블처럼 같은 날 안에서만 읽히는 자리.
  String displayTimeOnly(String localeName) =>
      DateFormat.jm(localeName).format(toLocal());

  static String _languageCode(String localeName) =>
      localeName.split(RegExp('[-_]')).first;
}
