package com.karma.walk

import android.content.Context
import com.gdelataillade.alarm.services.RingLog
import com.gdelataillade.alarm.services.RingLogKind
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `walk/ring_log` ↔ Dart `ChannelRingLogSource`. 울림 · 끔 · 스누즈는 포크 `AlarmService` 가
 * 포크 [RingLog] 에 직접 쓰고, 여기서는 Dart 가 읽고 건너뛰기를 덧붙인다. 메인 엔진(`MainActivity`)과
 * 헤드리스 엔진(`BackgroundDispatcher` — 미리 알림 [다음 알람 건너뛰기]) 양쪽에 붙는다.
 *
 * - `read` → `[String]`: 한 줄에 JSON 하나 `{"at", "packageId", "kind"}`, 오래된 것부터
 * - `append` ← `{at: epoch millis, packageId, kind}`
 */
internal class RingLogChannel private constructor(private val context: Context) :
    MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "walk/ring_log"

        fun attach(context: Context, messenger: BinaryMessenger) {
            MethodChannel(messenger, NAME)
                .setMethodCallHandler(RingLogChannel(context.applicationContext))
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "read" -> result.success(RingLog.read(context))
                "append" -> {
                    val at = call.argument<Number>("at")?.toLong()
                    val packageId = call.argument<Number>("packageId")?.toInt()
                    val kind = call.argument<String>("kind")?.let(RingLogKind::fromWire)
                    if (at == null || packageId == null || kind == null) {
                        result.error("bad_args", "append needs at, packageId, kind", null)
                    } else {
                        RingLog.append(context, packageId, kind, at)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("failed", e.message, null)
        }
    }
}
