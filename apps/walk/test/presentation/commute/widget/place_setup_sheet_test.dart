import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/commute/entity/commute_direction.dart';
import 'package:walk/domain/commute/entity/place.dart';
import 'package:walk/domain/commute/repository/address_search.dart';
import 'package:walk/presentation/commute/cubit/commute_cubit.dart';
import 'package:walk/presentation/commute/cubit/commute_state.dart';
import 'package:walk/presentation/commute/widget/place_setup_sheet.dart';

class _MockCubit extends MockCubit<CommuteState> implements CommuteCubit {}

const _home = Place(
  kind: PlaceKind.home,
  lat: 37.5,
  lng: 126.9,
  label: '동작구 상도동',
);

const _a = PlaceCandidate(lat: 37.1, lng: 127.1, label: '서울 강남구 역삼동');
const _b = PlaceCandidate(lat: 37.2, lng: 127.2, label: '서울 강남구 논현동');

void main() {
  late _MockCubit cubit;

  setUpAll(() {
    registerFallbackValue(PlaceKind.home);
    registerFallbackValue(_a);
  });

  setUp(() {
    cubit = _MockCubit();
    when(() => cubit.state).thenReturn(
      const CommuteState(direction: CommuteDirection.toWork, home: _home),
    );
  });

  Future<void> open(
    WidgetTester tester, {
    PlaceKind kind = PlaceKind.home,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<CommuteCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => showPlaceSetupSheet(context, kind),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('제목과 현재 라벨을 보여준다', (tester) async {
    await open(tester);
    expect(find.text('집'), findsOneWidget);
    expect(find.text('동작구 상도동'), findsOneWidget);
  });

  testWidgets('현재 위치 성공이면 시트가 닫힌다', (tester) async {
    when(
      () => cubit.useCurrentLocation(PlaceKind.home),
    ).thenAnswer((_) async => true);
    await open(tester);
    await tester.tap(find.text('현재 위치로'));
    await tester.pumpAndSettle();
    expect(find.text('현재 위치로'), findsNothing);
  });

  testWidgets('현재 위치 실패면 시트 안에 안내를 보이고 시트는 남는다', (tester) async {
    when(
      () => cubit.useCurrentLocation(PlaceKind.home),
    ).thenAnswer((_) async => false);
    await open(tester);
    await tester.tap(find.text('현재 위치로'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(PlaceSetupSheet),
        matching: find.text('위치를 가져오지 못했어요'),
      ),
      findsOneWidget,
    );
    expect(find.text('현재 위치로'), findsOneWidget);
  });

  testWidgets('검색 결과를 보여주고 누르면 저장하고 닫는다', (tester) async {
    when(() => cubit.searchAddress('강남')).thenAnswer((_) async => [_a, _b]);
    when(() => cubit.choosePlace(any(), any())).thenAnswer((_) async {});
    await open(tester, kind: PlaceKind.work);
    await tester.enterText(find.byType(TextField), '강남');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('서울 강남구 역삼동'), findsOneWidget);
    expect(find.text('서울 강남구 논현동'), findsOneWidget);

    await tester.tap(find.text('서울 강남구 논현동'));
    await tester.pumpAndSettle();
    verify(() => cubit.choosePlace(PlaceKind.work, _b)).called(1);
    expect(find.text('주소 검색'), findsNothing);
  });

  testWidgets('결과가 0건이면 안내 문구', (tester) async {
    when(() => cubit.searchAddress('없는곳')).thenAnswer((_) async => []);
    await open(tester);
    await tester.enterText(find.byType(TextField), '없는곳');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없어요'), findsOneWidget);
  });
}
