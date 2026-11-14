import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../format/alarm_format.dart';

/// 알람 시각 휠 — 반복 알람 편집 영역과 한 번 알람의 시각 시트가 같이 쓴다.
///
/// Material 의 `showTimePicker` 는 다이얼로그라 화면 안에 휠을 둘 수 없어, 알람 앱의 익숙한
/// 휠 모양을 위해 Cupertino 휠을 쓴다. 휠은 스스로 값을 들고 있어 [initial] 은 처음 한 번만 쓴다.
///
/// 화면 읽기: Cupertino 기본 시 열 라벨은 `12시 정각`(en `12 o'clock`)이라 분이 43 이어도
/// "정각"으로 읽힌다. 시 열 라벨만 `12시` 로 바꾸고, 휠 전체에는 지금 고른 시각(`오전 12:43`)을
/// 라벨로 단다.
class AlarmTimeWheel extends StatefulWidget {
  const AlarmTimeWheel({
    required this.initial,
    required this.onChanged,
    this.maximum,
    super.key,
  });

  final TimeOfDay initial;
  final ValueChanged<TimeOfDay> onChanged;

  /// 있으면 이보다 늦은 시각은 휠에서 고를 수 없다(일기 시각 — 오늘의 지금 이후 금지).
  /// [initial] 은 이보다 늦으면 안 된다.
  final TimeOfDay? maximum;

  @override
  State<AlarmTimeWheel> createState() => _AlarmTimeWheelState();
}

class _AlarmTimeWheelState extends State<AlarmTimeWheel> {
  late TimeOfDay _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: AlarmFormat.time(context, _value.hour, _value.minute),
      child: Localizations.override(
        context: context,
        delegates: [
          _WheelCupertinoLocalizationsDelegate(
            CupertinoLocalizations.of(context),
            hourLabel: l10n.walkAlarmWheelHourSemantics,
          ),
        ],
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          initialDateTime: DateTime(
            2000,
            1,
            1,
            widget.initial.hour,
            widget.initial.minute,
          ),
          maximumDate: switch (widget.maximum) {
            final max? => DateTime(2000, 1, 1, max.hour, max.minute),
            null => null,
          },
          onDateTimeChanged: (value) {
            final time = TimeOfDay(hour: value.hour, minute: value.minute);
            setState(() => _value = time);
            widget.onChanged(time);
          },
        ),
      ),
    );
  }
}

class _WheelCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _WheelCupertinoLocalizationsDelegate(
    this.base, {
    required this.hourLabel,
  });

  final CupertinoLocalizations base;
  final String Function(int hour) hourLabel;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture(_WheelCupertinoLocalizations(base, hourLabel));

  @override
  bool shouldReload(_WheelCupertinoLocalizationsDelegate old) =>
      old.base != base;
}

/// 시 열 화면 읽기 라벨만 바꾸고 나머지는 [_base] 에 그대로 맡긴다.
class _WheelCupertinoLocalizations extends CupertinoLocalizations {
  _WheelCupertinoLocalizations(this._base, this._hourLabel);

  final CupertinoLocalizations _base;
  final String Function(int hour) _hourLabel;

  @override
  String? datePickerHourSemanticsLabel(int hour) => _hourLabel(hour);

  // 아래는 그대로 넘긴다.
  @override
  String datePickerYear(int yearIndex) => _base.datePickerYear(yearIndex);
  @override
  String datePickerMonth(int monthIndex) => _base.datePickerMonth(monthIndex);
  @override
  String datePickerStandaloneMonth(int monthIndex) =>
      _base.datePickerStandaloneMonth(monthIndex);
  @override
  String datePickerDayOfMonth(int dayIndex, [int? weekDay]) =>
      _base.datePickerDayOfMonth(dayIndex, weekDay);
  @override
  String datePickerMediumDate(DateTime date) =>
      _base.datePickerMediumDate(date);
  @override
  String datePickerHour(int hour) => _base.datePickerHour(hour);
  @override
  String datePickerMinute(int minute) => _base.datePickerMinute(minute);
  @override
  String? datePickerMinuteSemanticsLabel(int minute) =>
      _base.datePickerMinuteSemanticsLabel(minute);
  @override
  DatePickerDateOrder get datePickerDateOrder => _base.datePickerDateOrder;
  @override
  DatePickerDateTimeOrder get datePickerDateTimeOrder =>
      _base.datePickerDateTimeOrder;
  @override
  String get anteMeridiemAbbreviation => _base.anteMeridiemAbbreviation;
  @override
  String get postMeridiemAbbreviation => _base.postMeridiemAbbreviation;
  @override
  String get todayLabel => _base.todayLabel;
  @override
  String get alertDialogLabel => _base.alertDialogLabel;
  @override
  String tabSemanticsLabel({required int tabIndex, required int tabCount}) =>
      _base.tabSemanticsLabel(tabIndex: tabIndex, tabCount: tabCount);
  @override
  String timerPickerHour(int hour) => _base.timerPickerHour(hour);
  @override
  String timerPickerMinute(int minute) => _base.timerPickerMinute(minute);
  @override
  String timerPickerSecond(int second) => _base.timerPickerSecond(second);
  @override
  String? timerPickerHourLabel(int hour) => _base.timerPickerHourLabel(hour);
  @override
  List<String> get timerPickerHourLabels => _base.timerPickerHourLabels;
  @override
  String? timerPickerMinuteLabel(int minute) =>
      _base.timerPickerMinuteLabel(minute);
  @override
  List<String> get timerPickerMinuteLabels => _base.timerPickerMinuteLabels;
  @override
  String? timerPickerSecondLabel(int second) =>
      _base.timerPickerSecondLabel(second);
  @override
  List<String> get timerPickerSecondLabels => _base.timerPickerSecondLabels;
  @override
  String get cutButtonLabel => _base.cutButtonLabel;
  @override
  String get copyButtonLabel => _base.copyButtonLabel;
  @override
  String get pasteButtonLabel => _base.pasteButtonLabel;
  @override
  String get clearButtonLabel => _base.clearButtonLabel;
  @override
  String get noSpellCheckReplacementsLabel =>
      _base.noSpellCheckReplacementsLabel;
  @override
  String get selectAllButtonLabel => _base.selectAllButtonLabel;
  @override
  String get lookUpButtonLabel => _base.lookUpButtonLabel;
  @override
  String get searchWebButtonLabel => _base.searchWebButtonLabel;
  @override
  String get shareButtonLabel => _base.shareButtonLabel;
  @override
  String get searchTextFieldPlaceholderLabel =>
      _base.searchTextFieldPlaceholderLabel;
  @override
  String get modalBarrierDismissLabel => _base.modalBarrierDismissLabel;
  @override
  String get menuDismissLabel => _base.menuDismissLabel;
  @override
  String get cancelButtonLabel => _base.cancelButtonLabel;
  @override
  String get backButtonLabel => _base.backButtonLabel;
  @override
  String get expansionTileExpandedHint => _base.expansionTileExpandedHint;
  @override
  String get expansionTileCollapsedHint => _base.expansionTileCollapsedHint;
  @override
  String get expansionTileExpandedTapHint => _base.expansionTileExpandedTapHint;
  @override
  String get expansionTileCollapsedTapHint =>
      _base.expansionTileCollapsedTapHint;
  @override
  String get expandedHint => _base.expandedHint;
  @override
  String get collapsedHint => _base.collapsedHint;
}
