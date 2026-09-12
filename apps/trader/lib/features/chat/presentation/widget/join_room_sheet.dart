import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/failure_localizations.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/chat_policy.dart';
import '../../domain/usecase/chat_use_case.dart';

/// 방에 들어가기 전 이 방에서 쓸 이름을 정하는 시트.
///
/// 기본값은 내 프로필 닉네임이다 — 대부분은 그대로 쓰고, 익명으로 있고 싶은
/// 사람만 고친다.
///
/// 입장 호출을 시트가 직접 한다. 실패하면 시트를 닫지 않고 문구를 남겨야 해서
/// 결과를 아는 자리가 여기여야 하기 때문이다 — 신고 시트(`ReportSheet`)와 같은
/// 모양이다.
class JoinRoomSheet extends StatefulWidget {
  const JoinRoomSheet._({required this.roomId, required this.defaultNickname});

  final String roomId;
  final String defaultNickname;

  /// 입장에 성공하면 `true` 로 닫힌다.
  static Future<bool> show(BuildContext context, String roomId) async {
    final nickname = switch (context.read<AuthBloc>().state) {
      AuthAuthenticated(:final user) => user.nickname,
      _ => '',
    };

    final joined = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          JoinRoomSheet._(roomId: roomId, defaultNickname: nickname),
    );
    return joined ?? false;
  }

  @override
  State<JoinRoomSheet> createState() => _JoinRoomSheetState();
}

class _JoinRoomSheetState extends State<JoinRoomSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.defaultNickname,
  );
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await getIt<ChatUseCase>().joinRoom(
      roomId: widget.roomId,
      nickname: _controller.text,
    );
    if (!mounted) return;

    result.when(
      ok: (_) => Navigator.of(context).pop(true),
      err: (failure) => setState(() {
        _submitting = false;
        _error = failure.localizedMessage(context);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      // 키보드가 올라와도 입력칸과 버튼이 가리지 않게 한다.
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.chatJoinTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.chatJoinDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: ChatPolicy.nicknameMaxLength,
            enabled: !_submitting,
            decoration: InputDecoration(
              labelText: l10n.chatJoinNicknameLabel,
              errorText: _error,
            ),
            onSubmitted: (_) => _submitting ? null : _submit(),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.primary(
            label: l10n.chatJoinAction,
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
