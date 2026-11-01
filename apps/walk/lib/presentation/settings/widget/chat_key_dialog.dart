import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/api_key_mask.dart';
import '../../../domain/chat/chat_vendor.dart';
import '../../chat/widget/chat_vendor_icon.dart';
import '../cubit/chat_settings_cubit.dart';

/// 대화상자가 닫힌 이유. 취소면 null.
enum ChatKeyDialogResult { connected, savedUnverified }

/// API 키 입력 대화상자(스펙 §1.2). 접두사를 보고, [저장]이면 확인 호출 → 요금 경고 →
/// 등록까지 이 안에서 끝낸다. 키가 거절되거나 쓰지 못하면 닫지 않는다.
class ChatKeyDialog extends StatefulWidget {
  const ChatKeyDialog({required this.vendor, super.key});

  final ChatVendor vendor;

  /// [context] 위의 ChatSettingsCubit 을 BlocProvider.value 로 넘겨 띄운다.
  static Future<ChatKeyDialogResult?> show(
    BuildContext context, {
    required ChatVendor vendor,
  }) {
    final cubit = context.read<ChatSettingsCubit>();
    return showDialog<ChatKeyDialogResult>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ChatKeyDialog(vendor: vendor),
      ),
    );
  }

  @override
  State<ChatKeyDialog> createState() => _ChatKeyDialogState();
}

class _ChatKeyDialogState extends State<ChatKeyDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _checking = false;

  /// 확인 호출이 키를 거절했는가. 글을 고치면 지운다.
  bool _rejected = false;

  /// 마지막으로 본 입력 — 선택 · 커서 이동만으로는 오류 문구를 지우지 않는다.
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_controller.text == _lastText) return;
    _lastText = _controller.text;
    setState(() => _rejected = false);
  }

  String get _key => _controller.text.trim();

  /// 접두사 안내. 비었거나 이 벤더의 키 모양이면 null.
  String? _prefixProblem(AppLocalizations l10n) {
    final key = _key;
    if (key.isEmpty) return null;
    final guessed = vendorOfKey(key);
    if (guessed == widget.vendor) return null;
    if (guessed != null) {
      return l10n.walkChatKeyOtherVendor(chatVendorName(l10n, guessed));
    }
    return l10n.walkChatKeyWrongPrefix(
      chatVendorName(l10n, widget.vendor),
      chatKeyPrefixHint(widget.vendor),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ChatSettingsCubit>();
    final key = _key;
    setState(() => _checking = true);
    final check = await cubit.check(key);
    if (!mounted) return;
    setState(() => _checking = false);
    if (check == ChatKeyCheck.invalid) {
      setState(() => _rejected = true);
      return;
    }
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkChatCostWarningTitle(chatVendorName(l10n, widget.vendor)),
      content: l10n.walkChatCostWarningBody(
        chatVendorCompany(l10n, widget.vendor),
      ),
      confirmLabel: l10n.walkChatCostWarningConfirm,
      isDestructive: false,
    );
    if (!confirmed || !mounted) return;
    final saved = await cubit.connect(key, check);
    if (!mounted) return;
    if (!saved) {
      AppSnackBar.show(
        context,
        message: l10n.walkChatSettingsSaveFailed,
        type: AppSnackBarType.error,
      );
      return;
    }
    Navigator.of(context).pop(
      check == ChatKeyCheck.valid
          ? ChatKeyDialogResult.connected
          : ChatKeyDialogResult.savedUnverified,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final problem = _prefixProblem(l10n);
    final canSave = !_checking && _key.isNotEmpty && problem == null;
    return PopScope<Object?>(
      canPop: !_checking,
      child: AlertDialog(
        title: Text(
          l10n.walkChatSettingsKeyDialogTitle(
            chatVendorName(l10n, widget.vendor),
          ),
        ),
        content: TextField(
          key: const Key('chat-key-input'),
          controller: _controller,
          enabled: !_checking,
          obscureText: _obscure,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: '${chatKeyPrefixHint(widget.vendor)}…',
            errorText: _rejected ? l10n.walkChatKeyInvalid : problem,
            suffixIcon: IconButton(
              key: const Key('chat-key-visibility'),
              tooltip: _obscure ? l10n.walkChatKeyShow : l10n.walkChatKeyHide,
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        actions: [
          AppButton.text(
            label: l10n.commonCancel,
            onPressed: _checking ? null : () => Navigator.of(context).pop(),
          ),
          AppButton.primary(
            key: const Key('chat-key-save'),
            label: l10n.walkChatSettingsSave,
            isLoading: _checking,
            onPressed: canSave ? _save : null,
          ),
        ],
      ),
    );
  }
}
