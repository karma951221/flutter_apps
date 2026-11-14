import 'package:freezed_annotation/freezed_annotation.dart';

part 'write_plan.freezed.dart';

/// 쓰기 도구 하나를 승인받기 전에 검증해 둔 계획. 디스크는 아직 그대로다.
/// [path] 는 `out/<이름>`, [name] 은 그 이름.
///
/// `previous` 는 준비 때 읽은 지금 내용 — 실행 직전에 다시 읽어 다르면 쓰지 않는다.
/// toString 은 종류와 글자 수만 — 경로 · 내용은 찍지 않는다.
@Freezed(toStringOverride: false)
sealed class WritePlan with _$WritePlan {
  const WritePlan._();

  /// 새 파일.
  const factory WritePlan.create({
    required String path,
    required String name,
    required String content,
  }) = WriteCreate;

  /// 있는 파일을 [content] 로 덮어쓴다.
  const factory WritePlan.overwrite({
    required String path,
    required String name,
    required String content,
    required String previous,
  }) = WriteOverwrite;

  /// [previous] 에 한 번 나오는 [oldText] 를 [newText] 로 바꾼 결과가 [content].
  const factory WritePlan.edit({
    required String path,
    required String name,
    required String oldText,
    required String newText,
    required String previous,
    required String content,
  }) = WriteEdit;

  /// 지운다. [sizeBytes] 는 준비 때 크기.
  const factory WritePlan.delete({
    required String path,
    required String name,
    required String previous,
    required int sizeBytes,
  }) = WriteDelete;

  @override
  String toString() => switch (this) {
    WriteCreate(:final content) =>
      'WritePlan.create(contentChars: ${content.runes.length})',
    WriteOverwrite(:final content, :final previous) =>
      'WritePlan.overwrite(contentChars: ${content.runes.length}, '
          'previousChars: ${previous.runes.length})',
    WriteEdit(:final oldText, :final newText, :final content) =>
      'WritePlan.edit(oldChars: ${oldText.runes.length}, '
          'newChars: ${newText.runes.length}, '
          'contentChars: ${content.runes.length})',
    WriteDelete(:final previous, :final sizeBytes) =>
      'WritePlan.delete(previousChars: ${previous.runes.length}, '
          'sizeBytes: $sizeBytes)',
  };
}
