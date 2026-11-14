import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/location/entity/map_style.dart';
import '../../../domain/location/repository/map_style_preferences.dart';

/// 지도 바탕 모양. 지도 탭과 지도 설정(셸 바깥 라우트)이 같은 것을 보도록 앱 전체에 하나다 —
/// 설정에서 바꾸면 뒤에 있는 지도가 바로 따라 바뀐다. 처음 값은 동기로 읽은 저장값.
@lazySingleton
class MapStyleCubit extends Cubit<MapStyle> {
  MapStyleCubit(this._preferences) : super(_preferences.style);

  final MapStylePreferences _preferences;

  /// 즉시 반영하고 저장한다.
  Future<void> select(MapStyle style) async {
    if (style == state) return;
    emit(style);
    await _preferences.setStyle(style);
  }

  @disposeMethod
  @override
  Future<void> close() => super.close();
}
