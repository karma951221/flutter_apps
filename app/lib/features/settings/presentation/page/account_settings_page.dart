import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_list_tile.dart';

/// 계정 설정 화면.
///
/// 계정 자체에 손대는 동작만 모은다. 프로필 값(닉네임·자기소개·사진) 수정은
/// profile feature 의 편집 화면이 소유하므로 여기 두지 않는다.
class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
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
            leading: const Icon(Icons.person_remove_outlined),
            title: const Text('회원 탈퇴'),
            subtitle: const Text('준비 중'),
            onTap: () => _showNotReady(context),
          ),
        ],
      ),
    ),
  );

  /// 회원 탈퇴는 아직 안내만 한다.
  ///
  /// 항목을 아예 감추지 않는 이유는, 탈퇴 경로가 없다고 오해한 사용자가 계정을
  /// 방치하는 것보다 "준비 중"을 보는 편이 낫기 때문이다. 되돌릴 수 없는 동작이라
  /// 정책이 정해지기 전에는 어떤 삭제 코드도 두지 않는다.
  //
  // TODO(F7): 회원 탈퇴 — Supabase Auth 사용자 삭제 RPC 와 데이터 정리 정책이
  // 정해진 뒤 구현한다
  Future<void> _showNotReady(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('준비 중입니다'),
      content: const Text('회원 탈퇴는 아직 제공하지 않습니다. 다음 업데이트에서 추가할 예정입니다.'),
      actions: [
        AppButton.text(
          label: '확인',
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}
