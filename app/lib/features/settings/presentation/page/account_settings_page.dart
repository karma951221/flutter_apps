import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/failure_localizations.dart';
import '../../../../core/result/result.dart';
import '../../../../design_system/widget/app_confirm_dialog.dart';
import '../../../../design_system/widget/app_list_tile.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/usecase/account_use_case.dart';
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
    final l10n = AppLocalizations.of(context);

    return BlocListener<DeleteAccountCubit, DeleteAccountState>(
      // 성공은 듣지 않는다 — 세션이 사라지면 라우터가 로그인 화면으로 보낸다.
      listener: (context, state) {
        if (state case DeleteAccountFailure(:final failure)) {
          AppSnackBar.show(
            context,
            message: failure.localizedMessage(context),
            type: AppSnackBarType.error,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.accountSettingsTitle)),
        body: SafeArea(
          child: ListView(
            children: [
              AppListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n.accountPasswordChange),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.changePassword),
              ),
              AppListTile(
                leading: Icon(
                  Icons.person_remove_outlined,
                  color: scheme.error,
                ),
                title: Text(
                  l10n.accountDelete,
                  style: TextStyle(color: scheme.error),
                ),
                subtitle: Text(l10n.accountDeleteSubtitle),
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
    final l10n = AppLocalizations.of(context);

    // 잃게 될 것을 이름과 숫자로 보여준다. 조회가 실패하면 종류만 적은 문구로
    // 물러선다 — 개수를 못 읽었다고 탈퇴를 막을 이유는 없다.
    final summary = await getIt<AccountUseCase>().myContentSummary();
    if (!context.mounted) return;
    final content = switch (summary) {
      Ok(:final value) => l10n.accountDeleteConfirmMessageCounted(
        value.postCount,
        value.commentCount,
      ),
      Err() => l10n.accountDeleteConfirmMessage,
    };

    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.accountDeleteConfirmTitle,
      content: content,
      confirmLabel: l10n.accountDeleteConfirmAction,
    );
    if (!confirmed) return;
    await cubit.submit();
  }
}
