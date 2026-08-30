import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../design_system/widget/app_confirm_dialog.dart';
import '../../../../design_system/widget/app_list_tile.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../cubit/delete_account_cubit.dart';
import '../cubit/delete_account_state.dart';

/// 계정 설정 화면.
///
/// 계정 자체에 손대는 동작만 모은다. 프로필 값(닉네임·자기소개·사진) 수정은
/// profile feature 의 편집 화면이 소유하므로 여기 두지 않는다.
class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<DeleteAccountCubit>(),
    child: const _AccountSettingsView(),
  );
}

class _AccountSettingsView extends StatelessWidget {
  const _AccountSettingsView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<DeleteAccountCubit, DeleteAccountState>(
      // 성공은 듣지 않는다 — 세션이 사라지면 라우터가 로그인 화면으로 보낸다.
      listener: (context, state) {
        if (state case DeleteAccountFailure(:final failure)) {
          AppSnackBar.show(
            context,
            message: failure.message ?? '탈퇴하지 못했습니다. 다시 시도해 주세요.',
            type: AppSnackBarType.error,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('계정 설정')),
        body: SafeArea(
          child: ListView(
            children: [
              AppListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('비밀번호 변경'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.changePassword),
              ),
              AppListTile(
                leading: Icon(Icons.person_remove_outlined, color: scheme.error),
                title: Text('회원 탈퇴', style: TextStyle(color: scheme.error)),
                subtitle: const Text('계정과 모든 기록이 즉시 삭제됩니다'),
                onTap: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 되돌릴 수 없는 동작이라 무엇이 지워지는지 먼저 보여주고 확인을 받는다.
  ///
  /// 실수로 누르는 것을 막는 장치는 확인 문구 하나로 충분하다고 봤다 —
  /// 비밀번호 재입력은 이 화면까지 오는 데 이미 세션이 필요하므로 검증 가치가
  /// 없고, 성가심만 더한다.
  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<DeleteAccountCubit>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: '정말 탈퇴할까요?',
      content:
          '계정과 함께 아래가 모두 삭제되며 되돌릴 수 없습니다.\n\n'
          '· 프로필과 프로필 사진\n'
          '· 작성한 게시물과 사진\n'
          '· 남긴 댓글과 감정표현',
      confirmLabel: '탈퇴',
    );
    if (!confirmed) return;
    await cubit.submit();
  }
}
