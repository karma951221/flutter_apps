import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../design_system/theme/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import 'router/app_router.dart';

class DaylogApp extends StatefulWidget {
  const DaylogApp({super.key});

  @override
  State<DaylogApp> createState() => _DaylogAppState();
}

class _DaylogAppState extends State<DaylogApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // AuthBloc 은 앱 수명 전체를 살고 라우터가 이걸 참조하므로 여기서 만든다.
    _authBloc = getIt<AuthBloc>()..add(const AuthEvent.started());
    _router = createRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'daylog',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      ),
    );
  }
}
