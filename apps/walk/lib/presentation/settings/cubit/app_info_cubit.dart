import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/app_info/app_info_source.dart';

/// 설정 탭 "앱 정보"의 버전 문자열. null = 아직 읽는 중.
class AppInfoCubit extends Cubit<String?> {
  AppInfoCubit(this._source) : super(null);

  final AppInfoSource _source;

  Future<void> load() async {
    final version = await _source.version();
    if (!isClosed) emit(version);
  }
}
