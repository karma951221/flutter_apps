import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 행 길게 누르기 시트의 동작 하나.
class RowAction<T> {
  const RowAction({
    required this.value,
    required this.label,
    required this.icon,
    this.isDestructive = false,
    this.key,
  });

  final T value;
  final String label;
  final IconData icon;

  /// 지우기처럼 되돌리기 어려운 동작 — 아이콘 · 글자가 error 색.
  final bool isDestructive;
  final Key? key;
}

/// 목록 행 길게 누르기 → 그 행의 동작 시트(대화 목록 · 작업 폴더).
///
/// 앱바 ⋮(화면 전체 동작)와 행 ⋮ 가 한 화면에 겹치지 않게, 행 동작은 여기로 옮긴다.
/// 제목은 그 행 이름(말풍선처럼 이름이 없으면 null). 고른 값을, 닫으면 null 을 돌려준다.
Future<T?> showRowActions<T>(
  BuildContext context, {
  required String? title,
  required List<RowAction<T>> actions,
}) => showAppSheet<T>(
  context: context,
  builder: (context) {
    final error = Theme.of(context).colorScheme.error;
    return AppSheetScaffold(
      title: title,
      children: [
        for (final a in actions)
          AppListTile(
            key: a.key,
            leading: Icon(a.icon, color: a.isDestructive ? error : null),
            title: Text(
              a.label,
              style: a.isDestructive ? TextStyle(color: error) : null,
            ),
            onTap: () => Navigator.pop(context, a.value),
          ),
      ],
    );
  },
);

/// 길게 누르기를 받는 행. [AppListTile] 에 길게 누르기 인자가 없어 바깥에서 받는다 —
/// 탭은 안쪽 [AppListTile] 이, 길게 누르기는 이 감지기가 이긴다.
class LongPressRow extends StatelessWidget {
  const LongPressRow({
    required this.onLongPress,
    required this.child,
    this.hint,
    super.key,
  });

  final VoidCallback onLongPress;

  /// 스크린 리더가 읽는 길게 누르기 설명(예: '이름 바꾸기 · 지우기').
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    onLongPressHint: hint,
    child: GestureDetector(onLongPress: onLongPress, child: child),
  );
}
