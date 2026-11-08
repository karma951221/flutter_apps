import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/location/background_location_access.dart';
import '../../../domain/location/entity/record_mode.dart';
import '../../../domain/location/entity/record_retention.dart';
import '../../../domain/location/recorder/location_recorder.dart';
import '../../../domain/location/recorder/recorder_status.dart';
import '../../../domain/location/repository/location_preferences.dart';
import '../../../domain/location/repository/location_repository.dart';
import 'map_record_state.dart';

/// 위치 기록을 켜고 끄고, 모드 · 보관 기간 · 지우기를 다룬다.
///
/// 셸이 하나를 소유해 지도 탭과 지도 설정이 같은 것을 본다.
class MapRecordCubit extends Cubit<MapRecordState> {
  MapRecordCubit(
    this._recorder,
    this._access,
    this._preferences,
    this._repository,
  ) : super(
        MapRecordState(
          status: const RecorderStatus.off(),
          busy: false,
          retention: _preferences.retention,
        ),
      );

  final LocationRecorder _recorder;
  final BackgroundLocationAccess _access;
  final LocationPreferences _preferences;
  final LocationRepository _repository;

  /// 서비스 상태(죽었으면 되살아난다) · 권한 · 보관 기간 · 저장된 점이 있는지를 읽는다.
  Future<void> load() async {
    if (state.busy) return;
    final status = await _recorder.status();
    final always = await _access.check();
    final activity = await _access.hasActivityRecognition();
    final notification = await _access.hasNotification();
    final hasPoints = await _repository.hasAnyPoint();
    if (isClosed) return;
    emit(
      state.copyWith(
        status: status,
        access: always,
        retention: _preferences.retention,
        activityRecognition: activity,
        notification: notification,
        hasPoints: hasPoints,
      ),
    );
  }

  /// 권한을 받고 평소 모드로 켠다. 항상 허용이 아니면 켜지 않고 [MapRecordState.access] 만 남긴다.
  Future<void> enable() async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      final access = await _access.request();
      if (access == AlwaysAccess.granted) {
        await _recorder.start(RecordMode.normal);
      }
      final status = await _recorder.status();
      final activity = await _access.hasActivityRecognition();
      final notification = await _access.hasNotification();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: status,
          access: access,
          activityRecognition: activity,
          notification: notification,
        ),
      );
    } finally {
      if (!isClosed) emit(state.copyWith(busy: false));
    }
  }

  Future<void> disable() async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      await _recorder.stop();
      if (isClosed) return;
      emit(state.copyWith(status: const RecorderStatus.off()));
    } finally {
      if (!isClosed) emit(state.copyWith(busy: false));
    }
  }

  /// 촘촘(true) · 평소(false). 기록 중이 아니면 아무것도 하지 않는다.
  Future<void> setDense(bool dense) async {
    if (state.busy || state.status is RecorderOff) return;
    emit(state.copyWith(busy: true));
    try {
      await _recorder.setMode(dense ? RecordMode.dense : RecordMode.normal);
      final status = await _recorder.status();
      if (isClosed) return;
      emit(state.copyWith(status: status));
    } finally {
      if (!isClosed) emit(state.copyWith(busy: false));
    }
  }

  Future<void> setRetention(RecordRetention value) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      await _preferences.setRetention(value);
      if (isClosed) return;
      emit(state.copyWith(retention: value));
    } finally {
      if (!isClosed) emit(state.copyWith(busy: false));
    }
  }

  Future<void> deleteAll() async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      await _repository.deleteAll();
      if (!isClosed) emit(state.copyWith(hasPoints: false));
    } finally {
      if (!isClosed) emit(state.copyWith(busy: false));
    }
  }

  Future<void> openAppSettings() => _access.openAppSettings();

  Future<void> openBatterySettings() => _recorder.openBatterySettings();
}
