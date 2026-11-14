import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/weather/entity/forecast.dart';
import '../../../domain/weather/repository/weather_repository.dart';
import '../../../domain/weather/weather_cache.dart';
import '../../../domain/weather/weather_locator.dart';
import '../../../domain/weather/weather_problem.dart';
import 'weather_state.dart';

/// 날씨 상단 탭의 예보를 읽는다. 처음엔 캐시를 먼저 보이고, 위치 · 네트워크가 실패하면
/// 마지막 성공(캐시)으로 버틴다.
@injectable
class WeatherCubit extends Cubit<WeatherState> {
  WeatherCubit(this._repository, this._locator, this._cache, this._clock)
    : super(const WeatherState.loading());

  /// 탭 전환 · 앱 복귀로는 마지막 성공이 이보다 최근이면 다시 부르지 않는다.
  static const freshFor = Duration(minutes: 10);

  /// 이보다 오래된 캐시는 쓰지 않는다(시간별 띠가 거의 지난 시간이 된다).
  static const cacheMaxAge = Duration(hours: 24);

  final WeatherRepository _repository;
  final WeatherLocator _locator;
  final WeatherCache _cache;
  final Clock _clock;

  /// 마지막 성공 한 벌과 그 예보. 저장소 캐시를 읽었거나 이번 실행에서 받은 것.
  CachedForecast? _last;
  Forecast? _lastForecast;

  /// 마지막 시도가 문제로 끝났는지. 실패한 시도는 10분 규칙으로 막지 않는다.
  bool _lastFailed = false;

  Future<void>? _inFlight;

  /// 날씨 탭이 보이게 될 때. 마지막 성공이 10분 안이면 다시 부르지 않는다.
  Future<void> shown() => _start(force: false);

  /// 보이는 상태에서 앱 복귀. [shown] 과 같은 10분 규칙.
  Future<void> resumed() => _start(force: false);

  /// 당겨서 새로고침 · 다시 시도. 항상 부른다.
  Future<void> refresh() => _start(force: true);

  /// [problem] 을 풀 설정 · 권한 화면을 연 뒤 다시 읽는다. 화면을 못 열어도 다시 읽는다.
  Future<void> resolve(WeatherProblem problem) async {
    try {
      await _locator.resolve(problem);
    } catch (e, s) {
      debugPrint('weather resolve failed: $e\n$s');
    }
    if (isClosed) return;
    await refresh();
  }

  /// 진행 중이면 같은 Future 를 돌려준다(요청 한 번).
  Future<void> _start({required bool force}) {
    final running = _inFlight;
    if (running != null) return running;
    final run = _run(force: force).whenComplete(() => _inFlight = null);
    _inFlight = run;
    return run;
  }

  Future<void> _run({required bool force}) async {
    if (_last == null) await _readCache();
    if (isClosed) return;

    final now = _clock.now();
    final usable = _usable(now);
    final current = state;
    if (!force &&
        !_lastFailed &&
        usable != null &&
        !now.isBefore(usable.fetchedAt) &&
        now.difference(usable.fetchedAt) < freshFor) {
      if (current is! WeatherLoaded) emit(_loadedFrom(usable));
      return;
    }

    final pending = switch (current) {
      WeatherLoaded() => current.copyWith(refreshing: true),
      _ when usable != null => _loadedFrom(usable, refreshing: true),
      _ => const WeatherState.loading(),
    };
    // 처음 상태가 이미 loading 이면 다시 내보내지 않는다.
    if (pending != current) emit(pending);

    final fix = await _locator.locate();
    if (isClosed) return;

    final double lat;
    final double lng;
    String? placeName;
    WeatherProblem? locationProblem;
    _NameLookup? pendingName;
    switch (fix) {
      case WeatherLocated(lat: final fixLat, lng: final fixLng):
        lat = fixLat;
        lng = fixLng;
        // 이름은 예보 요청을 막지 않는다 — 동시에 시작하고 늦으면 나중에 채운다.
        pendingName = _nameFor(lat, lng);
      case WeatherNoFix(:final problem):
        locationProblem = problem;
        final fallback = _usable(now);
        if (fallback == null) {
          _fail(WeatherState.empty(problem));
          return;
        }
        // 위치를 못 얻으면 캐시 좌표로 읽고 이름도 캐시 것을 쓴다.
        lat = fallback.lat;
        lng = fallback.lng;
        placeName = fallback.placeName;
    }

    final FetchedForecast fetched;
    try {
      fetched = await _repository.fetch(lat, lng);
    } catch (e, s) {
      final problem = switch (e) {
        WeatherFailure(:final problem) => problem,
        _ => WeatherProblem.server,
      };
      if (e is! WeatherFailure) debugPrint('weather fetch failed: $e\n$s');
      if (isClosed) return;
      final fallback = _usable(_clock.now());
      // 풀 수 있는 위치 문제(권한 · 서비스 꺼짐)가 먼저다 — 버튼이 있다.
      // 일시적인 위치 실패는 실제로 막은 쪽(예: 오프라인)을 알린다.
      final actionable =
          locationProblem == WeatherProblem.locationDenied ||
          locationProblem == WeatherProblem.locationServiceOff;
      final shownProblem = actionable ? locationProblem! : problem;
      _fail(
        fallback == null
            ? WeatherState.empty(shownProblem)
            : _loadedFrom(fallback, stale: true, problem: shownProblem),
      );
      return;
    }
    if (isClosed) return;

    // 이름이 예보보다 먼저 왔으면 함께 내보낸다.
    final early = pendingName != null && pendingName.done;
    if (early) placeName = pendingName.value;

    final saved = CachedForecast(
      payload: fetched.payload,
      lat: lat,
      lng: lng,
      placeName: placeName,
      fetchedAt: _clock.now(),
    );
    _last = saved;
    _lastForecast = fetched.forecast;
    _lastFailed = locationProblem != null;
    emit(
      WeatherState.loaded(
        forecast: fetched.forecast,
        placeName: placeName,
        fetchedAt: saved.fetchedAt,
        problem: locationProblem,
      ),
    );
    await _write(saved);

    if (pendingName != null && !early) {
      // 기다리지 않는다 — 당겨서 새로고침 표시가 이름 조회에 묶이지 않게.
      pendingName.future.then((name) => _applyName(saved, name));
    }
  }

  /// 장소 이름 조회를 시작한다. 실패는 null(화면은 "현재 위치").
  _NameLookup _nameFor(double lat, double lng) {
    final lookup = _NameLookup();
    Future<String?> raw;
    try {
      raw = _locator.placeName(lat, lng);
    } catch (e, s) {
      raw = Future.error(e, s);
    }
    lookup.future = raw
        .then<String?>(
          (name) => name,
          onError: (Object e, StackTrace s) {
            debugPrint('weather place name failed: $e\n$s');
            return null;
          },
        )
        .then((name) {
          lookup
            ..done = true
            ..value = name;
          return name;
        });
    return lookup;
  }

  /// 늦게 온 이름을, 그 사이 다른 예보로 바뀌지 않았을 때만 반영하고 캐시에도 쓴다.
  Future<void> _applyName(CachedForecast saved, String? name) async {
    if (isClosed || name == null || !identical(_last, saved)) return;
    final named = saved.copyWith(placeName: name);
    _last = named;
    final current = state;
    if (current is WeatherLoaded &&
        current.fetchedAt == saved.fetchedAt &&
        identical(current.forecast, _lastForecast)) {
      emit(current.copyWith(placeName: name));
    }
    await _write(named);
  }

  void _fail(WeatherState next) {
    _lastFailed = true;
    emit(next);
  }

  Future<void> _readCache() async {
    final cached = await _cache.read();
    if (cached == null) return;
    if (_clock.now().difference(cached.fetchedAt) > cacheMaxAge) return;
    try {
      _lastForecast = _repository.decode(cached.payload);
      _last = cached;
    } catch (e) {
      // 깨진 캐시는 없는 것으로 본다.
      debugPrint('weather cache decode failed: $e');
    }
  }

  /// 아직 쓸 수 있는(24시간 안) 마지막 성공.
  CachedForecast? _usable(DateTime now) {
    final last = _last;
    if (last == null || _lastForecast == null) return null;
    if (now.difference(last.fetchedAt) > cacheMaxAge) return null;
    return last;
  }

  WeatherLoaded _loadedFrom(
    CachedForecast cached, {
    bool refreshing = false,
    bool stale = false,
    WeatherProblem? problem,
  }) =>
      WeatherState.loaded(
            forecast: _lastForecast!,
            placeName: cached.placeName,
            fetchedAt: cached.fetchedAt,
            refreshing: refreshing,
            stale: stale,
            problem: problem,
          )
          as WeatherLoaded;

  Future<void> _write(CachedForecast value) async {
    try {
      await _cache.write(value);
    } catch (e, s) {
      debugPrint('weather cache write failed: $e\n$s');
    }
  }
}

/// 진행 중인 장소 이름 조회. 예보보다 먼저 끝났으면 [done] 이 켜져 있다.
class _NameLookup {
  late final Future<String?> future;
  bool done = false;
  String? value;
}
