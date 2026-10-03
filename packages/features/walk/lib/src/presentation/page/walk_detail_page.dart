import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../domain/entity/walk.dart';
import '../../domain/entity/walk_track_point.dart';
import '../cubit/walk_detail_cubit.dart';
import '../cubit/walk_detail_state.dart';
import '../widget/dog_avatars.dart';
import '../widget/route_map.dart';
import '../widget/walk_photo_grid.dart';
import '../widget/walk_stats_row.dart';

/// 산책 상세 화면. 지도 · 통계 · 반려견 · 사진 · 메모를 보이고 수정 · 삭제로 이어진다.
///
/// 라우팅은 모른다. [onEdit] 이 돌려주는 Future 가 끝나면(수정 화면에서 돌아오면)
/// 상세를 다시 읽는다. 삭제되면 [onDeleted] 가 한 번 불린다.
class WalkDetailPage extends StatelessWidget {
  const WalkDetailPage({
    required this.walkId,
    required this.onEdit,
    required this.onDeleted,
    super.key,
  });

  final String walkId;
  final Future<void> Function(String id) onEdit;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<WalkDetailCubit>()..load(walkId),
    child: _WalkDetailView(
      walkId: walkId,
      onEdit: onEdit,
      onDeleted: onDeleted,
    ),
  );
}

enum _WalkMenuAction { edit, delete }

class _WalkDetailView extends StatelessWidget {
  const _WalkDetailView({
    required this.walkId,
    required this.onEdit,
    required this.onDeleted,
  });

  final String walkId;
  final Future<void> Function(String id) onEdit;
  final VoidCallback onDeleted;

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

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.walkDetailTitle),
            actions: [
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
                      value: _WalkMenuAction.delete,
                      label: l10n.commonDelete,
                      icon: Icons.delete_outline,
                      isDestructive: true,
                    ),
                  ],
                  onSelected: (action) => switch (action) {
                    _WalkMenuAction.edit => _edit(context),
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

  static const _mapHeight = AppSpacing.xl * 8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<WalkDetailCubit>();
    final memo = walk.memo;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        SizedBox(
          height: _mapHeight,
          child: RouteMap(
            key: const Key('walk-detail-map'),
            points: [for (final p in track) p.point],
            follow: false,
            emptyMessage: l10n.walkNoTrack,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.walkDateLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                walk.startedAt.displayDateTime(l10n.localeName),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              WalkStatsRow(
                distanceMeters: walk.distanceMeters,
                elapsed: walk.duration,
              ),
              if (walk.dogs.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.walkDogsLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    DogAvatars(dogs: walk.dogs, photoFile: cubit.photoFile),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        walk.dogs.map((dog) => dog.name).join(', '),
                        key: const Key('walk-detail-dog-names'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
              if (walk.photos.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.walkPhotosLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                WalkPhotoGrid(photos: walk.photos, photoFile: cubit.photoFile),
              ],
              if (memo != null && memo.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  memo,
                  key: const Key('walk-detail-memo'),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
