import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/dog.dart';
import '../../domain/entity/walk.dart';
import '../../domain/entity/walk_draft.dart';
import '../../domain/entity/walk_session.dart';
import '../../domain/entity/walk_update.dart';

part 'walk_edit_form.freezed.dart';

/// 산책 저장 · 수정 폼 입력값. 신규는 [session], 수정은 [existing] 이 채워진다.
///
/// [photoPaths] 중 [existing] 에 없던 것이 이번 폼에서 쓴 파일이다([addedPhotoPaths]).
@freezed
class WalkEditForm with _$WalkEditForm {
  /// 한 산책에 붙일 수 있는 사진 수([기획 §9 #6]).
  static const maxPhotos = 10;

  @override
  final List<Dog> dogs;
  @override
  final Set<String> selectedDogIds;
  @override
  final String memo;
  @override
  final List<String> photoPaths;
  @override
  final WalkSession? session;
  @override
  final Walk? existing;

  const WalkEditForm({
    required this.dogs,
    required this.selectedDogIds,
    this.memo = '',
    this.photoPaths = const [],
    this.session,
    this.existing,
  });

  bool get isNew => existing == null;

  bool get isPhotoLimitReached => photoPaths.length >= maxPhotos;

  /// 요약 헤더용. 수정에서도 바뀌지 않는다.
  DateTime get startedAt => existing?.startedAt ?? session!.startedAt;

  double get distanceMeters =>
      existing?.distanceMeters ?? session!.distanceMeters;

  Duration get duration =>
      existing?.duration ??
      session!.elapsedAt(session!.endedAt ?? session!.startedAt);

  /// 이번 폼에서 파일로 쓴 사진 — 저장되지 않으면 지워야 한다.
  List<String> get addedPhotoPaths {
    final original = {for (final p in existing?.photos ?? const []) p.path};
    return [
      for (final path in photoPaths)
        if (!original.contains(path)) path,
    ];
  }

  String? get _trimmedMemo {
    final trimmed = memo.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<String> get _selectedIds => [
    for (final dog in dogs)
      if (selectedDogIds.contains(dog.id)) dog.id,
  ];

  WalkDraft toDraft() {
    final session = this.session!;
    return WalkDraft(
      startedAt: session.startedAt,
      endedAt: session.endedAt ?? session.startedAt,
      distanceMeters: session.distanceMeters,
      points: session.points,
      dogIds: _selectedIds,
      memo: _trimmedMemo,
      photoPaths: photoPaths,
    );
  }

  WalkUpdate toUpdate() => WalkUpdate(
    id: existing!.id,
    dogIds: _selectedIds,
    memo: _trimmedMemo,
    photoPaths: photoPaths,
  );
}
