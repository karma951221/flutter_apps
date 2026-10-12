import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 4자리 PIN 키패드. 4번째 숫자에서 [onCompleted] 로 넘기고 비운다.
///
/// 누른 숫자는 이 위젯이 들고 있어야 해서 `StatefulWidget` 이다(계획의 `StatelessWidget`
/// 시그니처와 생성자는 같다). [error] 면 점을 오류 색으로 그린다.
class PinPad extends StatefulWidget {
  const PinPad({
    required this.onCompleted,
    this.enabled = true,
    this.error = false,
    super.key,
  });

  static const length = 4;

  final ValueChanged<String> onCompleted;
  final bool enabled;
  final bool error;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _digits = '';

  void _press(String digit) {
    if (!widget.enabled) return;
    final next = _digits + digit;
    if (next.length < PinPad.length) {
      setState(() => _digits = next);
      return;
    }
    setState(() => _digits = '');
    widget.onCompleted(next);
  }

  void _delete() {
    if (!widget.enabled || _digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = widget.error ? scheme.error : scheme.primary;

    Widget key(String digit) => Expanded(
      child: AppButton.text(
        label: digit,
        onPressed: widget.enabled ? () => _press(digit) : null,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < PinPad.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(
                  i < _digits.length ? Icons.circle : Icons.circle_outlined,
                  size: AppSpacing.md,
                  color: color,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(children: [for (final d in row) key(d)]),
        Row(
          children: [
            const Spacer(),
            key('0'),
            Expanded(
              child: AppButton.text(
                label: l10n.walkLockPinDelete,
                onPressed: widget.enabled ? _delete : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
