import 'package:flutter/material.dart';

/// 저장된 세션을 확인하는 동안 보여준다.
///
/// 이 화면이 없으면 앱 시작 시 로그인 화면이 잠깐 번쩍였다가 홈으로 넘어간다.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
