package com.karma.walk

import android.Manifest
import android.content.ContentUris
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.os.Handler
import android.os.Looper
import android.provider.CalendarContract.Calendars
import android.provider.CalendarContract.Instances
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.LocalDate
import java.time.temporal.JulianFields
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * `walk/holidays` — 폰 캘린더(`CalendarContract`)의 휴일 캘린더에서 공휴일을 읽는다.
 *
 * - `read {from, to}`(`yyyy-MM-dd`, 양 끝 포함) → `[{date, name}]`, 권한 없음 · 휴일 캘린더 없음 ·
 *   공휴일 일정 없음 · 실패면 null(Dart 가 내장 표로 간다).
 * - `calendarName` → 고른 휴일 캘린더의 표시 이름 또는 null.
 *
 * 어느 캘린더를 고르고 무엇을 쉬는 날로 볼지는 [HolidayCalendarRules]. 질의는 메인 스레드를 막지 않게
 * 별도 스레드에서 한다. 메인 엔진은 [MainActivity] 가, 헤드리스 엔진은 백그라운드 실행기가 [attach] 한다.
 */
class HolidayCalendarChannel private constructor(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "walk/holidays"
        private const val TAG = "WalkHolidays"

        /** 엔진마다 채널을 붙여도 질의는 한 줄로 선다. 프로세스 수명 동안 하나. */
        private val worker: ExecutorService = Executors.newSingleThreadExecutor()
        private val main = Handler(Looper.getMainLooper())

        /** [engine] 에 `walk/holidays` 를 붙인다. 엔진이 내려가면 채널도 함께 사라진다. */
        @JvmStatic
        fun attach(context: Context, engine: FlutterEngine): HolidayCalendarChannel =
            HolidayCalendarChannel(context.applicationContext, engine.dartExecutor.binaryMessenger)
    }

    init {
        MethodChannel(messenger, NAME).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "read" -> {
                val from = call.argument<String>("from")?.let(::parseDay)
                val to = call.argument<String>("to")?.let(::parseDay)
                if (from == null || to == null) {
                    result.error("bad_args", "from and to are required (yyyy-MM-dd)", null)
                } else {
                    background(result) { read(from, to) }
                }
            }
            "calendarName" -> background(result) { calendars()?.firstOrNull()?.displayName }
            else -> result.notImplemented()
        }
    }

    private fun canRead(): Boolean =
        context.checkSelfPermission(Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED

    /** 휴일 캘린더들. 권한이 없거나 하나도 없으면 null. */
    private fun calendars(): List<HolidayCalendarRules.Picked>? {
        if (!canRead()) return null
        val projection = arrayOf(
            Calendars._ID,
            Calendars.ACCOUNT_TYPE,
            Calendars.OWNER_ACCOUNT,
            Calendars.CAL_SYNC1,
            Calendars._SYNC_ID,
            Calendars.CALENDAR_DISPLAY_NAME,
            Calendars.SYNC_EVENTS,
        )
        val rows = mutableListOf<HolidayCalendarRules.CalendarRow>()
        context.contentResolver.query(Calendars.CONTENT_URI, projection, null, null, null)?.use { c ->
            while (c.moveToNext()) {
                rows += HolidayCalendarRules.CalendarRow(
                    id = c.getLong(0),
                    accountType = c.stringOrNull(1),
                    ownerAccount = c.stringOrNull(2),
                    calSync1 = c.stringOrNull(3),
                    syncId = c.stringOrNull(4),
                    displayName = c.stringOrNull(5),
                    syncEvents = if (c.isNull(6)) 1 else c.getInt(6),
                )
            }
        }
        return HolidayCalendarRules.pick(rows).ifEmpty { null }
    }

    private fun read(from: LocalDate, to: LocalDate): List<Map<String, String>>? {
        val picked = calendars() ?: return null
        // BY_DAY 는 율리우스일로 묻는다. 종일 일정은 UTC 날짜라 시간대를 타지 않는다.
        val uri = Instances.CONTENT_BY_DAY_URI.buildUpon().also {
            ContentUris.appendId(it, from.getLong(JulianFields.JULIAN_DAY))
            ContentUris.appendId(it, to.getLong(JulianFields.JULIAN_DAY))
        }.build()
        val selection =
            "${Instances.CALENDAR_ID} IN (${picked.joinToString { "?" }}) AND ${Instances.ALL_DAY}=1"
        val args = picked.map { it.id.toString() }.toTypedArray()
        val projection = arrayOf(
            Instances.CALENDAR_ID,
            Instances.ALL_DAY,
            Instances.START_DAY,
            Instances.END_DAY,
            Instances.TITLE,
            Instances.DESCRIPTION,
        )
        val instances = mutableListOf<HolidayCalendarRules.InstanceRow>()
        context.contentResolver.query(uri, projection, selection, args, null)?.use { c ->
            while (c.moveToNext()) {
                instances += HolidayCalendarRules.InstanceRow(
                    calendarId = c.getLong(0),
                    allDay = c.getInt(1) == 1,
                    startDay = c.getInt(2),
                    endDay = c.getInt(3),
                    title = c.stringOrNull(4),
                    description = c.stringOrNull(5),
                )
            }
        }
        val days = HolidayCalendarRules.holidays(instances, picked) ?: return null
        return days
            .filterKeys { !it.isBefore(from) && !it.isAfter(to) }
            .map { (date, name) -> mapOf("date" to date.toString(), "name" to name) }
            .ifEmpty { null }
    }

    private fun parseDay(text: String): LocalDate? =
        try {
            LocalDate.parse(text)
        } catch (e: Exception) {
            null
        }

    private fun Cursor.stringOrNull(index: Int): String? = if (isNull(index)) null else getString(index)

    /** 권한 회수 · 제공자 오류(SecurityException 등)는 null 로 돌려 내장 표로 가게 한다. */
    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        worker.execute {
            val value =
                try {
                    work()
                } catch (e: Exception) {
                    Log.w(TAG, "holiday calendar read failed", e)
                    null
                }
            main.post { result.success(value) }
        }
    }
}
