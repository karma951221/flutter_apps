import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 지도 오른쪽 아래의 타일 출처 한 줄. "© <출처>".
///
/// flutter_map 의 `SimpleAttributionWidget` 은 'flutter_map | ' 을 앞에 박아 두고
/// 끌 수 없어서 따로 둔다. 출처는 타일 라이선스(OSM ODbL · CC-BY-SA · Esri 약관) 때문에
/// 늘 보이게 한다. 바탕을 테마 surface 로 깔아 어떤 지도 위에서도 읽힌다.
class MapAttribution extends StatelessWidget {
  /// © 뒤에 붙는 출처 문구.
  final String source;

  /// 아래를 가리는 시트 높이. 그만큼 위로 올린다.
  final double bottomInset;

  const MapAttribution({super.key, required this.source, this.bottomInset = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomRight,
          child: ColoredBox(
            color: scheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs / 2,
              ),
              child: Text(
                '© $source',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
