import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/core/di/injection.dart';
import 'package:walk/domain/transit/usecase/find_transit_routes.dart';
import 'package:walk/domain/transit/usecase/search_stations.dart';
import 'package:walk/domain/transit/usecase/transit_point_suggestions.dart';
import 'package:walk/domain/transit/usecase/verify_transit_key.dart';
import 'package:walk/presentation/transit/cubit/point_picker_cubit.dart';
import 'package:walk/presentation/transit/cubit/transit_cubit.dart';

/// 길찾기 등록이 실제 DI 그래프에서 풀리는지 본다. 미리 받는 값(prefs · 경로)만 가짜로 채운다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    final tmp = Directory.systemTemp.createTempSync('transit_di_test');
    addTearDown(() => tmp.deleteSync(recursive: true));
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(pathChannel, (_) async => tmp.path);
    addTearDown(() => messenger.setMockMethodCallHandler(pathChannel, null));
    await getIt.reset();
    addTearDown(getIt.reset);
    await configureDependencies();
  });

  test('transit use cases and cubits resolve from the graph', () async {
    expect(getIt<FindTransitRoutes>(), isA<FindTransitRoutes>());
    expect(getIt<SearchStations>(), isA<SearchStations>());
    expect(getIt<VerifyTransitKey>(), isA<VerifyTransitKey>());
    expect(getIt<TransitPointSuggestions>(), isA<TransitPointSuggestions>());

    final transit = getIt<TransitCubit>();
    final picker = getIt<PointPickerCubit>();
    expect(picker.debounce, const Duration(milliseconds: 500));
    expect(picker.composingDebounce, const Duration(milliseconds: 900));
    await transit.close();
    await picker.close();
  });
}
