import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../domain/entity/post.dart';
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
        : await cubit.create(_content.text);

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
