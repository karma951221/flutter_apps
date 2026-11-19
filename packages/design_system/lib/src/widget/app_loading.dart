import 'dart:async';

import 'package:flutter/material.dart';

/// 목록 · 화면 대신 자리를 채우는 읽는 중 표시 — 가운데 진행 표시 하나.
///
/// 빈칸(`SizedBox.shrink`)을 두면 읽는 중인지 비었는지 알 수 없어, 화면을 채우는 안내
/// `AppPlaceholder` 와 짝으로 둔다. 목록 끝의 더 읽는 중은 `AppListFooter` 가 맡는다.
///
/// 로컬 DB 처럼 대개 금방 끝나는 읽기는 [delayed] 를 켠다 — [delay] 동안은 빈칸으로
/// 두었다가 그때까지도 읽는 중이면 진행 표시를 그린다. 짧은 깜빡임을 막으려고 화면마다
/// 빈칸을 두던 판단을 여기로 모았다.
class AppLoading extends StatefulWidget {
  const AppLoading({this.delayed = false, super.key});

  /// 진행 표시를 [delay] 뒤에야 그릴지. 기본 false.
  final bool delayed;

  /// [delayed] 일 때 기다리는 시간.
  static const delay = Duration(milliseconds: 300);

  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _AppLoadingState extends State<AppLoading> {
  Timer? _timer;
  late bool _visible = !widget.delayed;

  @override
  void initState() {
    super.initState();
    if (!_visible) {
      _timer = Timer(AppLoading.delay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _visible
      ? const Center(child: CircularProgressIndicator())
      : const SizedBox.expand();
}
