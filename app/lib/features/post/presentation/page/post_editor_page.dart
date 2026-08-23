import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/media/image_picker_service.dart';
import '../../domain/entity/post.dart';
import '../../domain/entity/post_image_draft.dart';
import '../../domain/post_policy.dart';
import '../cubit/post_cubit.dart';

/// 게시물 작성·수정 화면.
///
/// 저장에 성공하면 결과 [Post] 를 들고 pop 한다. 목록 화면이 그 값으로
/// 자기 상태를 갱신한다.
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

  @override
  void initState() {
    super.initState();
    _content = TextEditingController(text: widget.post?.content);
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

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
          message: _isEditing ? '게시물을 수정했습니다.' : '게시물을 작성했습니다.',
          type: AppSnackBarType.success,
        );
        context.pop(post);
      },
      err: (failure) => AppSnackBar.show(
        context,
        message: failure.message ?? '게시물을 저장하지 못했습니다.',
        type: AppSnackBarType.error,
      ),
    );
  }

  Future<void> _pickImages() async {
    final remaining = 5 - _images.length;
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
          message: '이미지를 준비하지 못했습니다.',
          type: AppSnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select(
      (PostCubit cubit) => cubit.state.isSubmitting,
    );

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '게시물 수정' : '새 게시물 작성')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  // E2E 셀렉터.
                  key: const Key('postEditor.content'),
                  controller: _content,
                  enabled: !isSubmitting,
                  maxLength: PostPolicy.maxContentLength,
                  minLines: 6,
                  maxLines: 10,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: '오늘의 기록',
                    hintText: '지금 떠오르는 생각을 남겨보세요.',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final content = value?.trim() ?? '';
                    return content.isEmpty ? '게시물 내용을 입력하세요.' : null;
                  },
                ),
                if (!_isEditing) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    key: const Key('postEditor.addImages'),
                    onPressed: isSubmitting ? null : _pickImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text('사진 추가 (${_images.length}/5)'),
                  ),
                  if (_images.isNotEmpty)
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final bytes = _images[index].bytes;
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  bytes,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  tooltip: '사진 삭제',
                                  onPressed: isSubmitting
                                      ? null
                                      : () => setState(
                                          () => _images.removeAt(index),
                                        ),
                                  icon: const Icon(Icons.close),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: _isEditing ? '수정 완료' : '게시하기',
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
