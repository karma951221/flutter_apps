import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../design_system/theme/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/theme/domain/entity/app_theme_mode.dart';
import '../features/theme/presentation/cubit/theme_cubit.dart';
import 'router/app_router.dart';

class DaylogApp extends StatefulWidget {
  const DaylogApp({super.key});

  @override
  State<DaylogApp> createState() => _DaylogAppState();
}

class _DaylogAppState extends State<DaylogApp> {
  late final AuthBloc _authBloc;
  late final ThemeCubit _themeCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // AuthBloc 은 앱 수명 전체를 살고 라우터가 이걸 참조하므로 여기서 만든다.
    _authBloc = getIt<AuthBloc>()..add(const AuthEvent.started());
    // ThemeCubit 도 앱 수명 전체를 산다. 소비자가 MaterialApp.themeMode 라
    // 라우터·탭보다 위에 있어야 한다.
    _themeCubit = getIt<ThemeCubit>();
    _router = createRouter(_authBloc);
  }

  @override
  void dispose() {
    _themeCubit.close();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _themeCubit),
      ],
      child: BlocBuilder<ThemeCubit, AppThemeMode>(
        builder: (context, mode) => MaterialApp.router(
          title: 'daylog',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode.themeMode,
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
        ),
      ),
    );
  }
}
