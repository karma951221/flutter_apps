package com.karma.walk.location

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * `com.karma.walk/location_record` ↔ Dart `LocationRecorder`. 시각은 epoch millis(UTC).
 *
 * - `start` ← `{mode: "normal"|"dense"}`: 켜짐 · 모드를 저장하고 서비스를 띄운다(권한이 없으면
 *   저장만 — `status` 가 `blocked`).
 * - `stop`: 켜짐을 끄고 서비스를 끝낸다.
 * - `setMode` ← `{mode}`: 저장하고, 서비스가 떠 있으면 모드를 바꾼다.
 * - `status` → `{state: "off"|"running"|"blocked", mode, stillDetection}`. `stillDetection` 은 평소
 *   모드이고 활동 인식 권한이 있어 정지 감지가 도는지.
 * - `drain` ← `{limit}` → `[{id, t, lat, lng, acc?, mode, still}]` (id 오름차순, 지우지 않음)
 * - `ack` ← `{upToId}`: 그 id 이하를 inbox 에서 지운다.
 */
internal class LocationRecordChannel private constructor(private val context: Context) :
    MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "com.karma.walk/location_record"

        /** inbox 읽기 · 지우기는 UI 스레드 밖에서. 엔진이 다시 붙어도 스레드 하나를 나눠 쓴다. */
        private val io: ExecutorService = Executors.newSingleThreadExecutor()

        fun attach(context: Context, messenger: BinaryMessenger) {
            MethodChannel(messenger, NAME)
                .setMethodCallHandler(LocationRecordChannel(context.applicationContext))
        }
    }

    private val main = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "start" -> {
                    val mode = call.argument<String>("mode") ?: LocationRecordRules.MODE_NORMAL
                    start(mode)
                    result.success(null)
                }
                "stop" -> {
                    LocationRecordPrefs.setEnabled(context, false)
                    LocationRecordService.stop(context)
                    result.success(null)
                }
                "setMode" -> {
                    val mode = call.argument<String>("mode")
                    if (mode == null) {
                        result.error("bad_args", "setMode needs mode", null)
                    } else {
                        setMode(mode)
                        result.success(null)
                    }
                }
                "status" -> result.success(status())
                "drain" -> {
                    val limit = call.argument<Number>("limit")?.toInt()
                    if (limit == null) {
                        result.error("bad_args", "drain needs limit", null)
                    } else {
                        background(result) { drain(limit) }
                    }
                }
                "ack" -> {
                    val upToId = call.argument<Number>("upToId")?.toLong()
                    if (upToId == null) {
                        result.error("bad_args", "ack needs upToId", null)
                    } else {
                        background(result) {
                            LocationInbox.get(context).ack(upToId)
                            null
                        }
                    }
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("failed", e.message, null)
        }
    }

    private fun start(mode: String) {
        LocationRecordPrefs.setMode(context, mode)
        LocationRecordPrefs.setEnabled(context, true)
        // 떠 있으면 새 모드를 적용하고, 죽어 있으면 되살린다(새 인스턴스는 움직이는 중으로 시작).
        if (LocationRecordService.hasBackgroundPermission(context)) {
            LocationRecordService.start(context)
        }
    }

    /** 앱이 앞에 있는 지금, 켜짐 + 권한인데 서비스가 죽어 있으면 다시 띄운다. */
    private fun reviveIfDead() {
        val revive = LocationRecordRules.shouldRevive(
            enabled = LocationRecordPrefs.enabled(context),
            hasBackgroundPermission = LocationRecordService.hasBackgroundPermission(context),
            serviceRunning = LocationRecordService.running,
        )
        if (!revive) return
        try {
            LocationRecordService.start(context)
        } catch (e: Exception) {
            Log.w("LocationRecord", "revive failed", e)
        }
    }

    private fun setMode(mode: String) {
        LocationRecordPrefs.setMode(context, mode)
        if (LocationRecordService.running) {
            LocationRecordService.send(context, LocationRecordService.ACTION_SET_MODE)
        }
    }

    private fun status(): Map<String, Any> {
        reviveIfDead()
        val mode = LocationRecordPrefs.mode(context)
        return mapOf(
            "state" to LocationRecordRules.stateOf(
                enabled = LocationRecordPrefs.enabled(context),
                hasBackgroundPermission = LocationRecordService.hasBackgroundPermission(context),
                locationOn = LocationRecordService.isLocationOn(context),
            ),
            "mode" to mode,
            "stillDetection" to (
                mode == LocationRecordRules.MODE_NORMAL &&
                    LocationRecordService.hasActivityRecognition(context)
                ),
        )
    }

    private fun drain(limit: Int): List<Map<String, Any?>> =
        LocationInbox.get(context).drain(limit).map { point ->
            mapOf(
                "id" to point.id,
                "t" to point.t,
                "lat" to point.lat,
                "lng" to point.lng,
                "acc" to point.acc,
                "mode" to point.mode,
                "still" to point.still,
            )
        }

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("failed", e.message, null) }
            }
        }
    }
}
