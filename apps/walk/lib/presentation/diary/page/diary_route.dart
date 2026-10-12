import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/widget/diary_lock_gate.dart';

/// 게이트 바깥(잠겨도 살아 있는 자리)을 감싼다. [gated] 는 잠금 게이트를 씌운 화면.
typedef DiaryRouteScope = Widget Function(BuildContext context, Widget gated);

/// 일기 탭 위에 화면을 띄운다. 띄운 화면도 셸의 [DiaryLockCubit] 에 묶인 [DiaryLockGate]
/// 안에 있어 다시 잠기면 트리에서 빠지고 잠금 화면이 보인다(스펙 §7).
///
/// [scope] 는 게이트 **바깥**에 둘 것(예: 쓰던 기록을 들고 있는 cubit 의 주인)을 감싼다 —
/// 잠겼다 풀려도 그 상태는 메모리에 남는다. [context] 위에 [DiaryLockCubit] 가 있어야 한다.
Future<T?> pushDiaryRoute<T>(
  BuildContext context, {
  required WidgetBuilder page,
  DiaryRouteScope? scope,
}) {
  final lock = context.read<DiaryLockCubit>();
  return Navigator.of(context).push(
    MaterialPageRoute<T>(
      builder: (context) {
        // 잠금 화면에는 바탕이 필요하다. 풀리면 [page] 가 자기 Scaffold 를 그린다.
        final gated = Scaffold(
          body: DiaryLockGate(child: Builder(builder: page)),
        );
        return BlocProvider.value(
          value: lock,
          child: scope == null
              ? gated
              : Builder(builder: (context) => scope(context, gated)),
        );
      },
    ),
  );
}
