import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/app_info/app_info_source.dart';
import 'package:walk/presentation/settings/cubit/app_info_cubit.dart';

class _MockSource extends Mock implements AppInfoSource {}

void main() {
  blocTest<AppInfoCubit, String?>(
    'load 는 버전을 담는다',
    build: () {
      final source = _MockSource();
      when(source.version).thenAnswer((_) async => '1.0.0 (1)');
      return AppInfoCubit(source);
    },
    act: (cubit) => cubit.load(),
    expect: () => ['1.0.0 (1)'],
  );
}
