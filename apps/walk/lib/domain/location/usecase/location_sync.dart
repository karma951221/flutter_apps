import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../recorder/location_recorder.dart';
import '../repository/location_preferences.dart';
import '../repository/location_repository.dart';

/// 네이티브 inbox 의 점을 저장소로 옮기고 보관 기간이 지난 점을 지운다.
///
/// 저장(insertAll)이 먼저, 비우기(ack)가 나중이다. 중간에 죽어 같은 점이 다시
/// 와도 저장소가 중복을 무시하므로 개수는 그대로다.
@injectable
class LocationSync {
  LocationSync(
    this._recorder,
    this._repository,
    this._preferences,
    this._clock,
  );

  static const _batch = 2000;

  final LocationRecorder _recorder;
  final LocationRepository _repository;
  final LocationPreferences _preferences;
  final Clock _clock;

  Future<int>? _running;

  /// 새로 저장한 점 개수. 이미 도는 중이면 그 결과를 기다린다.
  Future<int> run() {
    final inFlight = _running;
    if (inFlight != null) return inFlight;
    final pass = _pass().whenComplete(() => _running = null);
    _running = pass;
    return pass;
  }

  Future<int> _pass() async {
    var added = 0;
    while (true) {
      final rows = await _recorder.drain(limit: _batch);
      if (rows.isEmpty) break;
      added += await _repository.insertAll([for (final r in rows) r.point]);
      await _recorder.ack(rows.last.id);
      if (rows.length < _batch) break;
    }
    final cutoff = _preferences.retention.cutoff(_clock.now());
    if (cutoff != null) await _repository.purgeBefore(cutoff);
    return added;
  }
}
