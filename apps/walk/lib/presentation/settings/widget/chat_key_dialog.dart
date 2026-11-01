import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/api_key_mask.dart';
import '../../../domain/chat/chat_vendor.dart';
import '../../chat/widget/chat_vendor_icon.dart';
import '../cubit/chat_settings_cubit.dart';

/// 대화상자가 닫힌 이유. 취소면 null.
/// [switched] 는 다른 벤더로 바꿔 확인까지 됐다 — 확인 못 하고 바꿨으면 [switchedUnverified].
/// [savedUnverified] 는 벤더를 바꾸지 않고(처음 연결 · 키 바꾸기) 확인 없이 저장했다.
enum ChatKeyDialogResult {
  connected,
  savedUnverified,
  switched,
  switchedUnverified,
}

/// API 키 입력 대화상자(스펙 §1.2 · §5.2). 접두사를 보고, [저장]이면 확인 호출 → 요금 경고
/// (벤더를 바꾸는 중이면 바꾸기 확인 창 하나) → 등록까지 이 안에서 끝낸다. 키가 거절되거나
/// 쓰지 못하면 닫지 않는다.
class ChatKeyDialog extends StatefulWidget {
  const ChatKeyDialog({required this.vendor, this.switchingFrom, super.key});

  final ChatVendor vendor;

  /// 지금 연결된(바꾸기 전) 벤더. null 이면 처음 연결 · 같은 벤더 키 바꾸기.
  final ChatVendor? switchingFrom;

  /// [context] 위의 ChatSettingsCubit 을 BlocProvider.value 로 넘겨 띄운다.
  static Future<ChatKeyDialogResult?> show(
    BuildContext context, {
    required ChatVendor vendor,
    ChatVendor? switchingFrom,
  }) {
    final cubit = context.read<ChatSettingsCubit>();
    return showDialog<ChatKeyDialogResult>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ChatKeyDialog(vendor: vendor, switchingFrom: switchingFrom),
      ),
    );
  }

  @override
  State<ChatKeyDialog> createState() => _ChatKeyDialogState();
}

class _ChatKeyDialogState extends State<ChatKeyDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  /// 확인 호출 중인가 — [저장] 로딩.
  bool _checking = false;

  /// 확인 · 요금 경고 · 쓰기 중 어디쯤이든 저장이 진행 중인가. 입력칸 · 버튼 · 뒤로를 막는다.
  bool _busy = false;

  /// 입력칸 아래에 붙인 저장 결과 오류(키 거절 · 쓰기 실패). 글을 고치면 지운다.
  String? _saveError;

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
    setState(() => _saveError = null);
  }

  String get _key => _controller.text.trim();

  /// 이 벤더의 키를 아직 치는 중일 수 있는가 — 안내를 미룬다.
  /// anthropic: `sk-ant-api` 의 앞부분이거나 `sk-ant-api` + 숫자까지.
  bool _maybeTyping(String key) => switch (widget.vendor) {
    ChatVendor.anthropic =>
      'sk-ant-api'.startsWith(key) || RegExp(r'^sk-ant-api\d*$').hasMatch(key),
    ChatVendor.openai => 'sk-'.startsWith(key),
  };

  /// 접두사 안내. 비었거나, 이 벤더의 키 모양이거나, 아직 그 모양을 치는 중이면 null.
  String? _prefixProblem(AppLocalizations l10n) {
    final key = _key;
    if (key.isEmpty || _maybeTyping(key)) return null;
    final guessed = vendorOfKey(key);
    if (guessed == widget.vendor) return null;
    // sk-ant- 로 시작하지만 API 키가 아닌 것(관리 키 등).
    if (widget.vendor == ChatVendor.anthropic && key.startsWith('sk-ant-')) {
      return l10n.walkChatKeyNotApiKey;
    }
    if (guessed != null) {
      return l10n.walkChatKeyOtherVendor(chatVendorName(l10n, guessed));
    }
    return l10n.walkChatKeyWrongPrefix(
      chatVendorName(l10n, widget.vendor),
      chatKeyPrefixHint(widget.vendor),
    );
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _checking = true;
    });
    final error = await _checkAndConnect();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _checking = false;
      if (error != null) _saveError = error;
    });
  }

  /// 확인 → 요금 경고(바꾸기면 바꾸기 확인) → 등록. 성공이면 닫고 null, 입력칸에 붙일
  /// 오류가 있으면 그 글, 경고를 취소했으면 null.
  Future<String?> _checkAndConnect() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ChatSettingsCubit>();
    final key = _key;
    final vendor = widget.vendor;
    final check = await cubit.check(vendor, key);
    if (!mounted) return null;
    if (check == ChatKeyCheck.invalid) return l10n.walkChatKeyInvalid;
    setState(() => _checking = false);
    if (!await _confirm(l10n) || !mounted) return null;
    setState(() => _checking = true);
    final saved = await cubit.connect(vendor, key, check);
    if (!mounted) return null;
    if (!saved) {
      AppSnackBar.show(
        context,
        message: l10n.walkChatSettingsSaveFailed,
        type: AppSnackBarType.error,
      );
      return l10n.walkChatSettingsSaveFailed;
    }
    Navigator.of(context).pop(switch ((check, widget.switchingFrom)) {
      (ChatKeyCheck.valid, null) => ChatKeyDialogResult.connected,
      (ChatKeyCheck.valid, _) => ChatKeyDialogResult.switched,
      (_, null) => ChatKeyDialogResult.savedUnverified,
      _ => ChatKeyDialogResult.switchedUnverified,
    });
    return null;
  }

  /// 처음 연결 · 키 바꾸기는 요금 경고(②), 벤더 바꾸기는 요금 · 키 삭제 · 동의 · 대화를
  /// 한 창으로 묶는다(스펙 §5.2).
  Future<bool> _confirm(AppLocalizations l10n) {
    final vendor = widget.vendor;
    final name = chatVendorName(l10n, vendor);
    final company = chatVendorCompany(l10n, vendor);
    final from = widget.switchingFrom;
    if (from == null) {
      return AppConfirmDialog.show(
        context,
        title: l10n.walkChatCostWarningTitle(name),
        content: l10n.walkChatCostWarningBody(company),
        confirmLabel: l10n.walkChatCostWarningConfirm,
        isDestructive: false,
      );
    }
    return AppConfirmDialog.show(
      context,
      title: l10n.walkChatSwitchVendorTitle(name),
      content: l10n.walkChatSwitchVendorBody(
        company,
        chatVendorName(l10n, from),
        name,
      ),
      confirmLabel: l10n.walkChatSwitchVendorAction,
      isDestructive: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final problem = _prefixProblem(l10n);
    // 아직 치는 중(안내 없음)이어도 이 벤더의 키 모양이 될 때까지 저장은 끈다.
    final canSave = !_busy && vendorOfKey(_key) == widget.vendor;
    return PopScope<Object?>(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(
          l10n.walkChatSettingsKeyDialogTitle(
            chatVendorName(l10n, widget.vendor),
          ),
        ),
        content: TextField(
          key: const Key('chat-key-input'),
          controller: _controller,
          enabled: !_busy,
          obscureText: _obscure,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: '${chatKeyPrefixHint(widget.vendor)}…',
            errorText: _saveError ?? problem,
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
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
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
