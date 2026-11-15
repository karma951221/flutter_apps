import 'package:flutter/material.dart';

/// 목록 · 화면 대신 자리를 채우는 읽는 중 표시 — 가운데 진행 표시 하나.
///
/// 빈칸(`SizedBox.shrink`)을 두면 읽는 중인지 비었는지 알 수 없어, 화면을 채우는 안내
/// `AppPlaceholder` 와 짝으로 둔다. 목록 끝의 더 읽는 중은 `AppListFooter` 가 맡는다.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}
