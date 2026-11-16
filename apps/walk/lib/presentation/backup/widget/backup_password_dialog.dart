import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 암호화된 백업 파일을 열 비밀번호를 묻는다. 넣은 비밀번호, 취소면 null.
/// [wrong] 이면 방금 넣은 것이 틀렸다고(또는 파일이 손상됐다고) 칸 아래에 알린다.
class BackupPasswordDialog extends StatefulWidget {
  const BackupPasswordDialog({this.wrong = false, super.key});

  /// 백업 비밀번호의 최소 길이(스펙 §5).
  static const minLength = 8;

  final bool wrong;

  static Future<String?> show(BuildContext context, {bool wrong = false}) =>
      showDialog<String>(
        context: context,
        builder: (_) => BackupPasswordDialog(wrong: wrong),
      );

  @override
  State<BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<BackupPasswordDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canOpen = _controller.text.isNotEmpty;
    return AlertDialog(
      title: Text(l10n.walkBackupPasswordTitle),
      content: BackupPasswordField(
        key: const Key('backup-password-input'),
        controller: _controller,
        label: l10n.walkBackupSheetPassword,
        autofocus: true,
        errorText: widget.wrong ? l10n.walkBackupFailPassword : null,
        onSubmitted: canOpen ? (_) => _open() : null,
      ),
      actions: [
        AppButton.text(
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          key: const Key('backup-password-open'),
          label: l10n.walkBackupPasswordOpen,
          onPressed: canOpen ? _open : null,
        ),
      ],
    );
  }
}

/// 가린 비밀번호 칸 + 보기/숨기기 버튼. 모양은 앱 `InputDecorationTheme` 을 따른다.
class BackupPasswordField extends StatefulWidget {
  const BackupPasswordField({
    required this.controller,
    required this.label,
    this.helperText,
    this.errorText,
    this.autofocus = false,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  State<BackupPasswordField> createState() => _BackupPasswordFieldState();
}

class _BackupPasswordFieldState extends State<BackupPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      autofocus: widget.autofocus,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          tooltip: _obscure
              ? l10n.walkBackupPasswordShow
              : l10n.walkBackupPasswordHide,
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
