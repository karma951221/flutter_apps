import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/alarm/widget/next_alarm_widget.dart';

/// `WidgetChannel.kt`(`walk/widget`)로 홈 화면 "다음 알람" 위젯(`NextAlarmWidgetProvider`)을 갱신한다.
/// 메인 엔진 · 헤드리스 엔진(하루 sync · 미리 알림 버튼) 양쪽에 붙는다.
///
/// 채널 약속:
/// - `update` ← `{rings: [{atMillis: epoch millis, title: String}]}`(이른 순). 네이티브는 저장하고
///   위젯을 다시 그린다. 그릴 때 기기 시각보다 뒤인 첫 회차를 보인다.
/// - `takeLaunch` → bool: 위젯을 눌러 앱이 열렸는가(읽으면 지운다)
///
/// 채널이 없으면(테스트 · 네이티브 미연결) 무시 · false. 네이티브 오류는 던진다.
@LazySingleton(as: NextAlarmWidget)
class ChannelNextAlarmWidget implements NextAlarmWidget {
  const ChannelNextAlarmWidget();

  static const channelName = 'walk/widget';
  static const _channel = MethodChannel(channelName);

  @override
  Future<void> show(List<WidgetRing> upcoming) async {
    try {
      await _channel.invokeMethod<void>('update', {
        'rings': [
          for (final (:at, :title) in upcoming)
            {'atMillis': at.millisecondsSinceEpoch, 'title': title},
        ],
      });
    } on MissingPluginException {
      // 네이티브가 없으면 위젯 없이 지낸다.
    }
  }

  @override
  Future<bool> takeLaunch() async {
    try {
      return await _channel.invokeMethod<bool>('takeLaunch') ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
