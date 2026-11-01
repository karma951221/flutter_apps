import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/repository/chat_usage_repository.dart';
import 'chat_usage_state.dart';

/// 달별 사용량. 처음은 이번 달, 뒤로는 13개월(이번 달 - 12)까지 — 사용량 보관 기간과 같다.
class ChatUsageCubit extends Cubit<ChatUsageState> {
  ChatUsageCubit(this._usage, this._clock) : super(_initial(_clock.now()));

  final ChatUsageRepository _usage;
  final Clock _clock;

  /// 이번 달에서 뒤로 갈 수 있는 달 수.
  static const _monthsBack = 12;

  static ChatUsageState _initial(DateTime now) =>
      ChatUsageState(year: now.year, month: now.month);

  /// 0년 0월부터 센 달 번호 — 비교 · 이동용.
  static int _index(int year, int month) => year * 12 + (month - 1);

  int get _current {
    final now = _clock.now();
    return _index(now.year, now.month);
  }

  int get _shown => _index(state.year, state.month);

  bool get canGoBack => _shown > _current - _monthsBack;

  bool get canGoForward => _shown < _current;

  /// 보고 있는 달을 다시 읽는다. 실패하면 usage 를 비우고 로딩만 멈춘다.
  Future<void> load() async {
    final year = state.year;
    final month = state.month;
    emit(state.copyWith(loading: true));
    try {
      final usage = await _usage.month(year, month);
      if (isClosed || state.year != year || state.month != month) return;
      emit(state.copyWith(usage: usage, loading: false));
    } on Object {
      if (isClosed || state.year != year || state.month != month) return;
      emit(state.copyWith(usage: null, loading: false));
    }
  }

  Future<void> previousMonth() async {
    if (!canGoBack) return;
    await _go(_shown - 1);
  }

  Future<void> nextMonth() async {
    if (!canGoForward) return;
    await _go(_shown + 1);
  }

  Future<void> _go(int index) async {
    emit(
      ChatUsageState(year: index ~/ 12, month: index % 12 + 1, loading: true),
    );
    await load();
  }

  /// 사용량 기록을 모두 지우고 다시 읽는다. 지우기 실패는 호출한 쪽으로 던진다.
  Future<void> clear() async {
    await _usage.deleteAll();
    await load();
  }
}
