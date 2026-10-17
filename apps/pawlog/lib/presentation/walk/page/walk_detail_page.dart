import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/walk/entity/walk.dart';
import '../../../domain/walk/entity/walk_track_point.dart';
import '../../dog/widget/dog_avatars.dart';
import '../../theme/pawlog_theme.dart';
import '../cubit/walk_detail_cubit.dart';
import '../cubit/walk_detail_state.dart';
import '../cubit/walk_export_result.dart';
import '../cubit/walk_share_cubit.dart';
import '../cubit/walk_share_state.dart';
import '../widget/route_map.dart';
import '../widget/walk_photos.dart';
import '../widget/walk_stats_row.dart';

/// 산책 상세 화면. 지도 · 통계 · 반려견 · 사진 · 메모를 보이고 수정 · 삭제로 이어진다.
///
/// 라우팅은 모른다. [onEdit] 이 돌려주는 Future 가 끝나면(수정 화면에서 돌아오면)
/// 상세를 다시 읽는다. 삭제되면 [onDeleted] 가 한 번 불린다. 로그인하지 않은 채
/// "모두에게 공유" 를 누르면 [onSignIn] 이 불린다 — 돌아와서 다시 누른다(plan 화면 표).
class WalkDetailPage extends StatelessWidget {
  const WalkDetailPage({
    required this.walkId,
    required this.onEdit,
    required this.onDeleted,
    required this.onSignIn,
    super.key,
  });

  final String walkId;
  final Future<void> Function(String id) onEdit;
  final VoidCallback onDeleted;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => getIt<WalkDetailCubit>()..load(walkId)),
      BlocProvider(create: (_) => getIt<WalkShareCubit>()..load(walkId)),
    ],
    child: _WalkDetailView(
      walkId: walkId,
      onEdit: onEdit,
      onDeleted: onDeleted,
      onSignIn: onSignIn,
    ),
  );
}

enum _WalkMenuAction { edit, export, share, delete }

class _WalkDetailView extends StatelessWidget {
  const _WalkDetailView({
    required this.walkId,
    required this.onEdit,
    required this.onDeleted,
    required this.onSignIn,
  });

  final String walkId;
  final Future<void> Function(String id) onEdit;
  final VoidCallback onDeleted;
  final VoidCallback onSignIn;

  /// 공유 · 공유 취소. 화면은 그대로 두고 스낵바만 띄운다 — 메뉴 라벨은 상태로 바뀐다.
  Future<void> _toggleShare(BuildContext context) async {
    final cubit = context.read<WalkShareCubit>();
    final l10n = AppLocalizations.of(context);
    final outcome = await cubit.toggle();
    if (!context.mounted) return;
    final (message, type) = switch (outcome) {
      WalkShareOutcome.shared => (l10n.walkSocialShared, AppSnackBarType.info),
      WalkShareOutcome.unshared => (
        l10n.walkSocialUnshared,
        AppSnackBarType.info,
      ),
      WalkShareOutcome.failed => (
        l10n.walkSocialShareFailed,
        AppSnackBarType.error,
      ),
      WalkShareOutcome.signInRequired ||
      WalkShareOutcome.ignored => (null, null),
    };
    if (outcome == WalkShareOutcome.signInRequired) onSignIn();
    if (message == null || type == null) return;
    AppSnackBar.show(context, message: message, type: type);
  }

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<WalkDetailCubit>();
    await onEdit(walkId);
    if (cubit.isClosed) return;
    await cubit.load(walkId);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<WalkDetailCubit>();
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkDeleteConfirmTitle,
      content: l10n.walkDeleteConfirmMessage,
      confirmLabel: l10n.commonDelete,
    );
    if (!confirmed || cubit.isClosed) return;
    await cubit.delete();
  }

  Future<void> _export(BuildContext context) async {
    final cubit = context.read<WalkDetailCubit>();
    final l10n = AppLocalizations.of(context);
    final result = await cubit.exportGpx();
    if (!context.mounted) return;
    final message = switch (result) {
      WalkExportShared() => null,
      WalkExportNoRoute() => l10n.walkExportNoRoute,
      WalkExportFailed() => l10n.walkExportFailed,
    };
    if (message == null) return;
    AppSnackBar.show(
      context,
      message: message,
      type: result is WalkExportFailed
          ? AppSnackBarType.error
          : AppSnackBarType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<WalkDetailCubit>();

    return BlocConsumer<WalkDetailCubit, WalkDetailState>(
      listenWhen: (previous, current) => switch (current) {
        WalkDetailDeleted() => true,
        WalkDetailLoaded(:final failure?) => switch (previous) {
          WalkDetailLoaded(failure: final before) => before != failure,
          _ => true,
        },
        _ => false,
      },
      listener: (context, state) {
        switch (state) {
          case WalkDetailDeleted():
            onDeleted();
          case WalkDetailLoaded(:final failure?):
            AppSnackBar.show(
              context,
              message: failure.localizedMessage(context),
              type: AppSnackBarType.error,
            );
          default:
            break;
        }
      },
      builder: (context, state) {
        final hasContent =
            state is WalkDetailLoaded || state is WalkDetailDeleting;
        final share = context.watch<WalkShareCubit>().state;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.walkDetailTitle),
            actions: [
              if (state
                  case WalkDetailLoaded(:final walk) ||
                      WalkDetailDeleting(:final walk))
                IconButton(
                  key: const Key('walk-detail-favorite'),
                  icon: Icon(
                    walk.isFavorite ? Icons.star : Icons.star_border,
                    // 지우는 중에는 누를 수 없다 — 꺼진 것으로 보이게 흐린 색.
                    color: state is WalkDetailDeleting
                        ? PawlogColors.of(context).textMuted
                        : PawlogColors.of(context).primary,
                  ),
                  tooltip: walk.isFavorite
                      ? l10n.walkFavoriteRemove
                      : l10n.walkFavoriteAdd,
                  onPressed: state is WalkDetailLoaded
                      ? cubit.toggleFavorite
                      : null,
                ),
              if (hasContent)
                AppOverflowMenu<_WalkMenuAction>(
                  key: const Key('walk-detail-menu'),
                  enabled: state is WalkDetailLoaded,
                  items: [
                    AppOverflowMenuItem(
                      value: _WalkMenuAction.edit,
                      label: l10n.walkEdit,
                      icon: Icons.edit_outlined,
                    ),
                    AppOverflowMenuItem(
                      key: const Key('walk-detail-export'),
                      value: _WalkMenuAction.export,
                      label: l10n.walkExportGpx,
                      icon: Icons.ios_share_outlined,
                    ),
                    // 공유 여부를 읽는 중이거나 Supabase 를 쓸 수 없으면 숨긴다.
                    if (share case WalkShareReady(:final shared))
                      AppOverflowMenuItem(
                        key: const Key('walk-detail-share'),
                        value: _WalkMenuAction.share,
                        label: shared
                            ? l10n.walkSocialUnshare
                            : l10n.walkSocialShare,
                        icon: shared
                            ? Icons.public_off_outlined
                            : Icons.public_outlined,
                      ),
                    AppOverflowMenuItem(
                      value: _WalkMenuAction.delete,
                      label: l10n.commonDelete,
                      icon: Icons.delete_outline,
                      isDestructive: true,
                    ),
                  ],
                  onSelected: (action) => switch (action) {
                    _WalkMenuAction.edit => _edit(context),
                    _WalkMenuAction.export => _export(context),
                    _WalkMenuAction.share => _toggleShare(context),
                    _WalkMenuAction.delete => _confirmDelete(context),
                  },
                ),
            ],
          ),
          body: SafeArea(
            child: switch (state) {
              WalkDetailLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              // 곧 onDeleted 로 화면을 떠난다.
              WalkDetailDeleted() => const SizedBox.shrink(),
              WalkDetailFailure(:final failure) => Center(
                child: AppPlaceholder(
                  message: failure.localizedMessage(context),
                  actionLabel: l10n.commonRetry,
                  onAction: () => cubit.load(walkId),
                ),
              ),
              WalkDetailLoaded(:final walk, :final track) ||
              WalkDetailDeleting(
                :final walk,
                :final track,
              ) => _Content(walk: walk, track: track),
            },
          ),
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.walk, required this.track});

  final Walk walk;
  final List<WalkTrackPoint> track;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final styles = PawlogTextStyles.of(context);
    final cubit = context.read<WalkDetailCubit>();
    final memo = walk.memo;

    return ListView(
      padding: const EdgeInsets.only(bottom: PawlogSpacing.xl),
      children: [
        SizedBox(
          height: PawlogSize.detailMap,
          child: RouteMap(
            key: const Key('walk-detail-map'),
            points: [for (final p in track) p.point],
            follow: false,
            animateDraw: true,
            emptyMessage: l10n.walkNoTrack,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PawlogSize.gutter,
            PawlogSpacing.lg,
            PawlogSize.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                walk.startedAt.displayDateTime(l10n.localeName),
                style: theme.textTheme.titleLarge,
              ),
              if (walk.dogs.isNotEmpty) ...[
                const SizedBox(height: PawlogSpacing.md),
                Row(
                  children: [
                    DogAvatars(dogs: walk.dogs, photoFile: cubit.photoFile),
                    const SizedBox(width: PawlogSpacing.sm),
                    Expanded(
                      child: Text(
                        walk.dogs.map((dog) => dog.name).join(', '),
                        key: const Key('walk-detail-dog-names'),
                        style: styles.dogName,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: PawlogSpacing.lg),
              WalkStatsRow(
                distanceMeters: walk.distanceMeters,
                elapsed: walk.duration,
              ),
              if (walk.photos.isNotEmpty) ...[
                const SizedBox(height: PawlogSpacing.xl),
                WalkPhotos(photos: walk.photos, photoFile: cubit.photoFile),
              ],
              // 빈 메모는 자리를 차지하지 않는다.
              if (memo != null && memo.trim().isNotEmpty) ...[
                const SizedBox(height: PawlogSpacing.lg),
                Text(
                  memo,
                  key: const Key('walk-detail-memo'),
                  style: styles.memo,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
