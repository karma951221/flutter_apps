import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/media/image_picker_service.dart';
import '../../../../design_system/theme/app_radius.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../domain/entity/post.dart';
import '../../domain/entity/post_image_draft.dart';
import '../../domain/post_policy.dart';
import '../cubit/post_cubit.dart';
import '../../../../l10n/app_localizations.dart';

/// 게시물 작성·수정 화면.
///
/// 저장에 성공하면 결과 [Post] 를 들고 pop 한다. 목록 화면이 그 값으로
/// 자기 상태를 갱신한다.
///
/// 작성과 수정이 한 화면을 쓴다. 다른 것은 제목·버튼 라벨과 **사진 첨부 가능
/// 여부**뿐이다 — 수정은 본문만 바꾼다(`update_post_scenario`).
class PostEditorPage extends StatefulWidget {
  const PostEditorPage({this.post, super.key});

  final Post? post;

  @override
  State<PostEditorPage> createState() => _PostEditorPageState();
}

class _PostEditorPageState extends State<PostEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _content;
  final List<PreparedImage> _images = [];

  bool get _isEditing => widget.post != null;

  /// 나갈 때 버려질 내용이 있는지. 수정 화면은 처음 값과 달라졌을 때만 묻는다.
  bool get _hasUnsavedChanges {
    final typed = _content.text.trim();
    if (_isEditing) return typed != (widget.post?.content.trim() ?? '');
    return typed.isNotEmpty || _images.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _content = TextEditingController(text: widget.post?.content);
    // 남은 글자 수 표시가 입력마다 따라오도록 다시 그린다.
    _content.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _content
      ..removeListener(_onContentChanged)
      ..dispose();
    super.dispose();
  }

  void _onContentChanged() => setState(() {});

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final l10n = AppLocalizations.of(context);
    final cubit = context.read<PostCubit>();
    final result = _isEditing
        ? await cubit.update(widget.post!.id, _content.text)
        : await cubit.create(
            _content.text,
            images: _images
                .map(
                  (image) => PostImageDraft(
                    bytes: image.bytes,
                    width: image.width,
                    height: image.height,
                    contentType: image.contentType,
                    extension: image.extension,
                  ),
                )
                .toList(),
          );

    if (!mounted) return;
    result.when(
      ok: (post) {
        AppSnackBar.show(
          context,
          message: _isEditing ? l10n.postUpdated : l10n.postCreated,
          type: AppSnackBarType.success,
        );
        context.pop(post);
      },
      err: (failure) => AppSnackBar.show(
        context,
        message: failure.message ?? l10n.postSaveFailed,
        type: AppSnackBarType.error,
      ),
    );
  }

  Future<void> _pickImages() async {
    final remaining = PostPolicy.maxImageCount - _images.length;
    if (remaining <= 0) return;
    try {
      final picked = await getIt<ImagePickerService>().pickImages(
        limit: remaining,
      );
      if (mounted) setState(() => _images.addAll(picked));
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: AppLocalizations.of(context).postImagePrepareFailed,
          type: AppSnackBarType.error,
        );
      }
    }
  }

  /// 쓰던 내용을 두고 나가려 할 때 한 번 묻는다.
  ///
  /// 되돌릴 수 없는 손실이라 확인을 받는다. 아무것도 쓰지 않았으면 묻지 않는다 —
  /// 잘못 들어왔다가 나가는 흔한 경우까지 붙잡으면 성가시기만 하다.
  Future<bool> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _isEditing ? l10n.postDiscardEditTitle : l10n.postDiscardCreateTitle,
        ),
        content: Text(l10n.postDiscardMessage),
        actions: [
          AppButton.text(
            label: l10n.postDiscardKeepWriting,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton.text(
            label: l10n.postDiscardLeave,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSubmitting = context.select(
      (PostCubit cubit) => cubit.state.isSubmitting,
    );

    return PopScope(
      // 저장 중에는 나갈 수 없다. 화면이 사라진 뒤 결과가 오면 돌려줄 곳이 없다.
      canPop: !isSubmitting && !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || isSubmitting) return;
        final router = GoRouter.of(context);
        if (await _confirmDiscard() && mounted) router.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? l10n.postEditTitle : l10n.postCreateTitle),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                TextFormField(
                  // E2E 셀렉터.
                  key: const Key('postEditor.content'),
                  controller: _content,
                  enabled: !isSubmitting,
                  maxLength: PostPolicy.maxContentLength,
                  // 글자 수는 아래에서 직접 그린다. 기본 카운터는 남은 글자가
                  // 얼마 없다는 사실을 색으로 알려주지 못한다.
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        required maxLength,
                      }) => null,
                  minLines: 6,
                  maxLines: 10,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.postContentLabel,
                    hintText: l10n.postContentHint,
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final content = value?.trim() ?? '';
                    return content.isEmpty ? l10n.postContentRequired : null;
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                _ContentCounter(length: _content.text.characters.length),
                if (!_isEditing) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ImagePicker(
                    images: _images,
                    isSubmitting: isSubmitting,
                    onPick: _pickImages,
                    onRemove: (index) =>
                        setState(() => _images.removeAt(index)),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton.primary(
                  label: _isEditing
                      ? l10n.postSaveButton
                      : l10n.postSubmitButton,
                  onPressed: _submit,
                  isLoading: isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 남은 글자 수. 정책 상수를 화면이 다시 적지 않는다.
class _ContentCounter extends StatelessWidget {
  const _ContentCounter({required this.length});

  /// 경고로 바뀌는 지점. 한 줄 정도 남았을 때부터 알린다.
  static const _warningThreshold = 20;

  final int length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = PostPolicy.maxContentLength - length;
    final isWarning = remaining <= _warningThreshold;

    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$length / ${PostPolicy.maxContentLength}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: isWarning
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 사진 첨부 영역. 최대 장수는 [PostPolicy] 가 정한다.
class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.images,
    required this.isSubmitting,
    required this.onPick,
    required this.onRemove,
  });

  static const _thumbnailSize = 96.0;

  final List<PreparedImage> images;
  final bool isSubmitting;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFull = images.length >= PostPolicy.maxImageCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const Key('postEditor.addImages'),
          // 최대 장수에 닿으면 누를 수 없다. 최종 판정은 DB 의 sort_order 제약이다.
          onPressed: isSubmitting || isFull ? null : onPick,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(
            isFull
                ? l10n.postImageLimitReached(PostPolicy.maxImageCount)
                : l10n.postAddImages(images.length, PostPolicy.maxImageCount),
          ),
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: _thumbnailSize,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.smAll,
                    child: Image.memory(
                      images[index].bytes,
                      width: _thumbnailSize,
                      height: _thumbnailSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      tooltip: l10n.postRemoveImageTooltip,
                      visualDensity: VisualDensity.compact,
                      onPressed: isSubmitting ? null : () => onRemove(index),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
