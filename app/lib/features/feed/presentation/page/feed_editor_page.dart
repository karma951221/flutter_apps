import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/result/result.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../domain/entity/feed_post.dart';
import '../cubit/feed_cubit.dart';

class FeedEditorPage extends StatefulWidget {
  const FeedEditorPage({this.post, super.key});

  final FeedPost? post;

  @override
  State<FeedEditorPage> createState() => _FeedEditorPageState();
}

class _FeedEditorPageState extends State<FeedEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _content;
  bool _isSubmitting = false;

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
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final FeedCubit cubit = context.read<FeedCubit>();
    final Result<FeedPost> result = _isEditing
        ? await cubit.update(widget.post!.id, _content.text)
        : await cubit.create(_content.text);

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.when(
      ok: (_) {
        AppSnackBar.show(
          context,
          message: _isEditing ? '게시물을 수정했습니다.' : '게시물을 작성했습니다.',
          type: AppSnackBarType.success,
        );
        context.pop();
      },
      err: (failure) => AppSnackBar.show(
        context,
        message: failure.message ?? '게시물을 저장하지 못했습니다.',
        type: AppSnackBarType.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_isEditing ? '피드 수정' : '새 피드 작성')),
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
                enabled: !_isSubmitting,
                maxLength: 500,
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
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
