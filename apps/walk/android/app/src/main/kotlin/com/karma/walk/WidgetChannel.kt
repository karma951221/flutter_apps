package com.karma.walk

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `walk/widget` ↔ Dart `ChannelNextAlarmWidget`. 메인 엔진(`MainActivity`)과 헤드리스 엔진
 * (`BackgroundDispatcher` — 하루 sync · 미리 알림 버튼)에 모두 붙는다 — 어느 sync 든 위젯을 갱신한다.
 *
 * - `update` ← `{rings: [{atMillis: epoch millis, title}]}`: 저장하고 위젯을 다시 그린다
 * - `takeLaunch` → bool: 위젯을 눌러 앱을 열었는가([launchPending], 읽으면 지운다)
 */
internal class WidgetChannel private constructor(private val context: Context) :
    MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "walk/widget"

        /** 위젯을 눌러 [MainActivity] 가 열렸다. Dart 가 `takeLaunch` 로 읽으면 지운다. 메인 스레드. */
        var launchPending = false

        fun attach(context: Context, messenger: BinaryMessenger) {
            MethodChannel(messenger, NAME)
                .setMethodCallHandler(WidgetChannel(context.applicationContext))
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "update" -> {
                    val rows = call.argument<List<Any?>>("rings")
                    if (rows == null) {
                        result.error("bad_args", "update needs rings", null)
                        return
                    }
                    val rings = rows.mapNotNull { row ->
                        val map = row as? Map<*, *> ?: return@mapNotNull null
                        val at = (map["atMillis"] as? Number)?.toLong() ?: return@mapNotNull null
                        WidgetRing(at, map["title"] as? String ?: "")
                    }
                    NextAlarmWidgetStore.write(context, rings)
                    NextAlarmWidgetProvider.updateAll(context)
                    result.success(null)
                }
                "takeLaunch" -> {
                    val launched = launchPending
                    launchPending = false
                    result.success(launched)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("failed", e.message, null)
        }
    }
}
