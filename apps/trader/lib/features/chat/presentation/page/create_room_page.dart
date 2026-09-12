import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/chat_policy.dart';
import '../cubit/create_room_cubit.dart';
import 'chat_room_page.dart';

/// 방 만들기.
///
/// 만들자마자 개설자를 그 방에 넣는다. 방에서 쓸 이름을 여기서 함께 받는 이유는
/// 만든 사람도 참여자이고, 참여자에게는 방별 닉네임이 있어야 하기 때문이다.
class CreateRoomPage extends StatelessWidget {
  const CreateRoomPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<CreateRoomCubit>(),
    child: const _CreateRoomView(),
  );
}

class _CreateRoomView extends StatefulWidget {
  const _CreateRoomView();

  @override
  State<_CreateRoomView> createState() => _CreateRoomViewState();
}

class _CreateRoomViewState extends State<_CreateRoomView> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  late final TextEditingController _nickname;

  int _memberLimit = ChatPolicy.memberLimitDefault;

  @override
  void initState() {
    super.initState();
    final defaultNickname = switch (context.read<AuthBloc>().state) {
      AuthAuthenticated(:final user) => user.nickname,
      _ => '',
    };
    _nickname = TextEditingController(text: defaultNickname);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<CreateRoomCubit, CreateRoomState>(
      listener: (context, state) {
        switch (state) {
          case CreateRoomSuccess(:final room):
            // 만든 방으로 곧바로 들어간다. 목록 화면에는 true 를 돌려줘
            // 새 줄이 생겼음을 알린다.
            //
            // pop 이 이 화면을 걷어내므로 그 뒤에 `context` 를 쓰면 안 된다.
            // 라우터를 먼저 붙잡아 둔다.
            final router = GoRouter.of(context);
            // 딥링크로 이 화면에 바로 들어왔으면 되돌아갈 자리가 없다.
            // 그대로 pop 하면 go_router 가 던진다.
            if (router.canPop()) router.pop(true);
            router.push(
              Routes.chatRoomPath(room.id),
              extra: ChatRoomPageArgs(title: room.title).toMap(),
            );
          case CreateRoomFailure(:final failure):
            AppSnackBar.show(
              context,
              message: failure.localizedMessage(context),
              type: AppSnackBarType.error,
            );
          case CreateRoomIdle() || CreateRoomInProgress():
            break;
        }
      },
      builder: (context, state) {
        final submitting = state is CreateRoomInProgress;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.chatCreateTitle)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                TextField(
                  key: const Key('createRoom.title'),
                  controller: _title,
                  autofocus: true,
                  enabled: !submitting,
                  maxLength: ChatPolicy.roomTitleMaxLength,
                  decoration: InputDecoration(
                    labelText: l10n.chatRoomTitleLabel,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  key: const Key('createRoom.description'),
                  controller: _description,
                  enabled: !submitting,
                  maxLength: ChatPolicy.roomDescriptionMaxLength,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.chatRoomDescriptionLabel,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  key: const Key('createRoom.nickname'),
                  controller: _nickname,
                  enabled: !submitting,
                  maxLength: ChatPolicy.nicknameMaxLength,
                  decoration: InputDecoration(
                    labelText: l10n.chatNicknameLabel,
                    helperText: l10n.chatJoinDescription,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.chatMemberLimitValue(_memberLimit),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Slider(
                  value: _memberLimit.toDouble(),
                  min: ChatPolicy.memberLimitMin.toDouble(),
                  max: ChatPolicy.memberLimitMax.toDouble(),
                  divisions: _sliderDivisions,
                  label: '$_memberLimit',
                  onChanged: submitting
                      ? null
                      : (value) => setState(
                          () => _memberLimit = CreateRoomCubit.clampMemberLimit(
                            value.round(),
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton.primary(
                  key: const Key('createRoom.submit'),
                  label: l10n.chatCreateAction,
                  isLoading: submitting,
                  onPressed: submitting ? null : _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 2명 단위로 고를 수 있게 나눈다.
  static const _sliderDivisions =
      (ChatPolicy.memberLimitMax - ChatPolicy.memberLimitMin) ~/ 2;

  void _submit() => context.read<CreateRoomCubit>().submit(
    title: _title.text,
    description: _description.text,
    memberLimit: _memberLimit,
    nickname: _nickname.text,
  );
}
