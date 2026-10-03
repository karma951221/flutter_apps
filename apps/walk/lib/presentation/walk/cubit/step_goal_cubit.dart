import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/settings/repository/settings_repository.dart';
import '../../../domain/walk/entity/step_goal.dart';

/// 하루 걸음 목표. `MaterialApp` 위에 두어 걷기 탭과 설정 탭이 같은 값을 본다.
class StepGoalCubit extends Cubit<int> {
  StepGoalCubit(this._repository) : super(_repository.load().stepGoal);

  final SettingsRepository _repository;

  Future<void> select(int goal) async {
    final next = StepGoal.clamp(goal);
    if (next == state) return;
    emit(next);
    await _repository.save(_repository.load().copyWith(stepGoal: next));
  }
}
