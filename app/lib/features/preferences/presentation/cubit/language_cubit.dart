import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entity/app_language.dart';
import '../../domain/usecase/preferences_use_case.dart';

/// 앱 전체의 언어를 소유한다. `DaylogApp` 에서 만들어 앱 수명 전체를 산다.
///
/// `ThemeCubit` 과 같은 모양이다 — 상태는 [AppLanguage] 값 하나이고, 생성자가
/// 저장된 값을 동기로 읽어 첫 프레임부터 옳은 언어로 뜬다.
@injectable
class LanguageCubit extends Cubit<AppLanguage> {
  LanguageCubit(this._useCase) : super(_useCase.loadLanguage());

  final PreferencesUseCase _useCase;

  /// 고른 언어를 즉시 적용하고 기기에 남긴다.
  ///
  /// 저장 실패는 삼킨다 — 화면은 이미 바뀌었고, 실패하면 다음 실행에 이전 값으로
  /// 뜰 뿐이다(계획서).
  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) return;
    emit(language);
    try {
      await _useCase.saveLanguage(language);
    } on Exception {
      // 주석의 근거대로 삼킨다. 화면은 이미 바뀌었고, 저장 실패를 오류로
      // 알리는 편이 더 성가시다 (2026-08-30 리뷰: 주석만 있고 코드가 없었다).
    }
  }
}

/// domain 의 [AppLanguage] 를 `Locale` 과 화면 문구로 옮긴다.
extension AppLanguageX on AppLanguage {
  /// `MaterialApp.locale` 에 넣을 값. 시스템은 null 이다 — null 이면 Flutter 가
  /// 기기 locale 협상을 하므로 시스템 ↔ 명시 언어 왕복이 값 하나로 끝난다.
  Locale? get locale => switch (this) {
    AppLanguage.system => null,
    AppLanguage.korean => const Locale('ko'),
    AppLanguage.english => const Locale('en'),
    AppLanguage.japanese => const Locale('ja'),
  };

  /// 선택 다이얼로그가 쓰는 표시 이름.
  ///
  /// 언어 이름은 **각 언어의 자기 표기로 고정**한다. 언어를 잘못 바꿔 읽지 못하는
  /// 화면에 갇혀도 자기 언어를 찾을 수 있어야 하기 때문이다(계획서). 번역이
  /// 아니므로 ARB 에 넣지 않는다. '시스템 설정'만 현재 언어를 따른다.
  String label(BuildContext context) => switch (this) {
    AppLanguage.system => AppLocalizations.of(context).languageSystem,
    AppLanguage.korean => '한국어',
    AppLanguage.english => 'English',
    AppLanguage.japanese => '日本語',
  };
}
