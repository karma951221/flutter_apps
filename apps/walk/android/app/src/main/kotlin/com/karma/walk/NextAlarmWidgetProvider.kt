package com.karma.walk

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.text.format.DateFormat
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.time.ZoneId
import java.util.Date
import java.util.Locale

/**
 * 홈 화면 "다음 알람" 위젯(웨이브 4 C5). 내용은 Dart 가 sync 끝에 `walk/widget` 의 `update` 로 넘긴
 * 회차들([NextAlarmWidgetStore])에서 **그릴 때** 고른다([NextAlarmWidgetRules]). 누르면 앱 알람 탭을 연다.
 *
 * 다시 그리는 때: 앱의 `update`, 날짜 · 시각 · 시간대 변경 방송, 그리고 보이는 회차가 지나거나
 * 자정이 될 때 거는 다시 그리기 알람([ACTION_REFRESH]). `ACTION_DATE_CHANGED` 는 Android 8+ 에서
 * 매니페스트 수신기에 오지 않을 수 있어 자정 알람이 문구(오늘 → 내일)를 맡는다.
 */
class NextAlarmWidgetProvider : AppWidgetProvider() {
    companion object {
        const val ACTION_REFRESH = "com.karma.walk.WIDGET_REFRESH"

        /** 위젯을 눌러 연 [MainActivity] 의 인텐트 액션. Dart 가 `takeLaunch` 로 읽어 알람 탭을 연다. */
        const val ACTION_OPEN_ALARMS = "com.karma.walk.OPEN_ALARMS"

        /** 놓인 위젯을 모두 다시 그린다. 하나도 없으면 다시 그리기 알람만 걷는다. */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, NextAlarmWidgetProvider::class.java))
            if (ids.isEmpty()) {
                cancelRefresh(context)
                return
            }
            render(context, manager, ids)
        }

        private fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val rings = NextAlarmWidgetStore.read(context)
            val now = System.currentTimeMillis()
            val zone = ZoneId.systemDefault()
            val ring = NextAlarmWidgetRules.pick(rings, now)
            val views = RemoteViews(context.packageName, R.layout.widget_next_alarm)
            if (ring == null) {
                views.setTextViewText(R.id.widget_when, context.getString(R.string.widget_empty))
                views.setViewVisibility(R.id.widget_title, View.GONE)
            } else {
                views.setTextViewText(R.id.widget_when, whenText(context, ring.atMillis, now, zone))
                views.setTextViewText(R.id.widget_title, ring.title)
                views.setViewVisibility(
                    R.id.widget_title,
                    if (ring.title.isBlank()) View.GONE else View.VISIBLE,
                )
            }
            views.setOnClickPendingIntent(R.id.widget_root, openAlarmsIntent(context))
            manager.updateAppWidget(ids, views)
            scheduleRefresh(context, NextAlarmWidgetRules.nextRefreshAt(rings, now, zone))
        }

        /** "오늘 오전 7:00" · "내일 (목) 오전 7:00" · "10월 9일 (금) 오전 7:00". 기기 언어 · 12/24시간. */
        private fun whenText(context: Context, atMillis: Long, nowMillis: Long, zone: ZoneId): String {
            val date = Date(atMillis)
            val locale = context.resources.configuration.locales[0] ?: Locale.getDefault()
            val time = DateFormat.getTimeFormat(context).format(date)
            return when (NextAlarmWidgetRules.dayOf(atMillis, nowMillis, zone)) {
                WidgetDay.TODAY -> context.getString(R.string.widget_today, time)
                WidgetDay.TOMORROW -> context.getString(
                    R.string.widget_tomorrow,
                    DateFormat.format(DateFormat.getBestDateTimePattern(locale, "EEE"), date),
                    time,
                )
                WidgetDay.LATER -> context.getString(
                    R.string.widget_later,
                    DateFormat.format(DateFormat.getBestDateTimePattern(locale, "MMMdEEE"), date),
                    time,
                )
            }
        }

        private fun openAlarmsIntent(context: Context): PendingIntent = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java)
                .setAction(ACTION_OPEN_ALARMS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        private fun refreshIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            Intent(context, NextAlarmWidgetProvider::class.java).setAction(ACTION_REFRESH),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        /** 깨우지 않는 정확하지 않은 알람 — 화면이 꺼져 있으면 켜질 때 다시 그려도 된다. */
        private fun scheduleRefresh(context: Context, atMillis: Long) {
            context.getSystemService(AlarmManager::class.java)
                .set(AlarmManager.RTC, atMillis, refreshIntent(context))
        }

        private fun cancelRefresh(context: Context) {
            context.getSystemService(AlarmManager::class.java).cancel(refreshIntent(context))
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_REFRESH,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            -> updateAll(context)
            else -> super.onReceive(context, intent)
        }
    }

    override fun onDisabled(context: Context) {
        cancelRefresh(context)
    }
}

/**
 * 위젯이 고를 회차들. SharedPreferences `walk_widget` 의 `rings` 에 JSON 배열
 * `[{"atMillis", "title"}]`(org.json). Dart `update` 가 통째로 바꾼다.
 */
internal object NextAlarmWidgetStore {
    private const val PREFS = "walk_widget"
    private const val KEY = "rings"

    fun write(context: Context, rings: List<WidgetRing>) {
        val array = JSONArray()
        for (ring in rings) array.put(JSONObject().put("atMillis", ring.atMillis).put("title", ring.title))
        // 헤드리스 엔진은 곧 내려가 프로세스가 끝날 수 있어 바로 쓴다(항목은 스무 개 이하).
        prefs(context).edit().putString(KEY, array.toString()).commit()
    }

    fun read(context: Context): List<WidgetRing> = try {
        val array = JSONArray(prefs(context).getString(KEY, null) ?: "[]")
        (0 until array.length()).map {
            val o = array.getJSONObject(it)
            WidgetRing(o.getLong("atMillis"), o.optString("title"))
        }
    } catch (e: org.json.JSONException) {
        emptyList()
    }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
