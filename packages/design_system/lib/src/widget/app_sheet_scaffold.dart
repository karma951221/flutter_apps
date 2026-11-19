import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// 모달 바텀시트를 여는 공통 진입점.
///
/// 손잡이(`showDragHandle`) · 위쪽 안전 영역 · 키보드에 밀려 올라가기
/// (`isScrollControlled`)를 늘 같은 값으로 켠다. 시트 안쪽 틀은
/// [AppSheetScaffold] 가 맡는다 — 둘을 짝으로 쓰면 어느 화면의 시트든 손잡이 ·
/// 제목 · 여백이 같다.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
}) => showModalBottomSheet<T>(
  context: context,
  builder: builder,
  showDragHandle: true,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: isDismissible,
  enableDrag: enableDrag,
  useRootNavigator: useRootNavigator,
);

/// 바텀시트 안쪽 틀 — 제목 · (설명) · 내용 · (아래 버튼).
///
/// 높이는 두 가지만 쓴다.
/// - 기본 생성자: 내용만큼. 화면보다 길어지면 내용만 스크롤된다.
/// - [AppSheetScaffold.draggable]: 긴 목록. 끌어서 키우고 줄인다.
///
/// 제목은 `titleLarge` 왼쪽 정렬, 좌우 여백은 [AppSpacing.lg] 다. 안의
/// `ListTile` 도 같은 좌우 여백으로 맞춰 글자 줄이 제목과 나란하다. 키보드가
/// 올라오면 그만큼 위로 밀린다. 손잡이는 [showAppSheet] 이 그린다.
class AppSheetScaffold extends StatelessWidget {
  const AppSheetScaffold({
    required this.title,
    required this.children,
    this.description,
    this.titleTrailing,
    this.primaryAction,
    this.secondaryAction,
    this.bodyPadding = EdgeInsets.zero,
    super.key,
  }) : _draggable = false,
       initialSize = 0,
       minSize = 0,
       maxSize = 0;

  /// 긴 목록용 — 끌어서 [minSize] ~ [maxSize] 사이로 키우고 줄인다.
  const AppSheetScaffold.draggable({
    required this.title,
    required this.children,
    this.description,
    this.titleTrailing,
    this.primaryAction,
    this.secondaryAction,
    this.bodyPadding = EdgeInsets.zero,
    this.initialSize = 0.6,
    this.minSize = 0.3,
    this.maxSize = 0.95,
    super.key,
  }) : _draggable = true;

  /// 없으면 머리를 그리지 않는다. 시간 고르기처럼 내용이 곧 제목인 시트만 비운다.
  final String? title;

  /// 제목 밑 한두 줄 설명.
  final String? description;

  /// 제목 줄 오른쪽 — 아이콘 버튼 하나 정도.
  final Widget? titleTrailing;
  final List<Widget> children;

  /// 아래 버튼. 보통 `AppButton.primary` · `AppButton.secondary`.
  final Widget? primaryAction;
  final Widget? secondaryAction;

  /// 내용 둘레 여백. 목록 행은 스스로 여백을 가지므로 기본은 0 이다. 자유 형식
  /// 내용(입력란 · 문단)이면 [AppSheetScaffold.contentPadding] 을 넘긴다.
  final EdgeInsetsGeometry bodyPadding;

  final double initialSize;
  final double minSize;
  final double maxSize;
  final bool _draggable;

  /// 자유 형식 내용의 좌우 여백 — 제목과 같은 선.
  static const contentPadding = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

  @override
  Widget build(BuildContext context) {
    final header = _SheetHeader(
      title: title,
      description: description,
      trailing: titleTrailing,
    );
    final actions = _actions();
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    Widget body;
    if (_draggable) {
      body = DraggableScrollableSheet(
        expand: false,
        initialChildSize: initialSize,
        minChildSize: minSize,
        maxChildSize: maxSize,
        builder: (context, controller) => Column(
          children: [
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.zero,
                children: [
                  header,
                  // 여백이 없으면 행을 목록에 바로 넣어 보이는 것만 그린다.
                  if (bodyPadding == EdgeInsets.zero)
                    ...children
                  else
                    Padding(
                      padding: bodyPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                ],
              ),
            ),
            ?actions,
          ],
        ),
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Flexible(
            child: SingleChildScrollView(
              padding: bodyPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
          ?actions,
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        top: false,
        child: ListTileTheme.merge(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: body,
          ),
        ),
      ),
    );
  }

  Widget? _actions() {
    final primary = primaryAction;
    final secondary = secondaryAction;
    if (primary == null && secondary == null) return null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          if (secondary != null) Expanded(child: secondary),
          if (primary != null && secondary != null)
            const SizedBox(width: AppSpacing.sm),
          if (primary != null) Expanded(child: primary),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.description,
    required this.trailing,
  });

  final String? title;
  final String? description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final description = this.description;
    if (title == null && description == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                ?trailing,
              ],
            ),
          if (description != null) ...[
            if (title != null) const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 시트 손잡이 — 모달이 아닌 시트(지도 위에 깔린 끌기형 등)가 직접 그릴 때 쓴다.
///
/// 모달 시트의 손잡이(`showDragHandle`)와 같은 크기 · 색을 테마에서 읽는다.
class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});

  /// Material 3 기본 손잡이 크기.
  static const _defaultSize = Size(32, 4);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheetTheme = theme.bottomSheetTheme;
    final size = sheetTheme.dragHandleSize ?? _defaultSize;
    final color =
        sheetTheme.dragHandleColor ??
        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    return Padding(
      // 모달 손잡이와 같은 48 높이 자리.
      padding: EdgeInsets.symmetric(vertical: (48 - size.height) / 2),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size.height / 2),
          ),
          child: SizedBox.fromSize(size: size),
        ),
      ),
    );
  }
}

/// 시트 위쪽 모서리 — walk 테마의 bottomSheetTheme 와 지도 시트가 같이 쓴다.
const appSheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
);
