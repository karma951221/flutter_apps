import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 앱 셸. 화면은 v1 구현 단계에서 `presentation/` 에 채운다.
class WalkApp extends StatelessWidget {
  const WalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '걷기',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: Text('걷기'))),
    );
  }
}
