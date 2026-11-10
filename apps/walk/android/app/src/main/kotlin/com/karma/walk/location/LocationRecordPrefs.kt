package com.karma.walk.location

import android.content.Context
import android.content.SharedPreferences

/**
 * 위치 기록의 켜짐 · 모드 · 정지 감지 단계. Flutter 없이(부팅 리시버 · 다시 뜬 서비스) 읽어야 해서
 * 네이티브 SharedPreferences `location_record` 에 둔다.
 */
internal object LocationRecordPrefs {
    private const val FILE = "location_record"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_MODE = "mode"
    private const val KEY_PHASE = "phase"
    private const val KEY_STILL_SINCE = "stillSince"
    private const val KEY_LAST_T = "lastT"
    private const val KEY_LAST_LAT = "lastLat"
    private const val KEY_LAST_LNG = "lastLng"
    private const val KEY_LAST_ACC = "lastAcc"

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun enabled(context: Context): Boolean = prefs(context).getBoolean(KEY_ENABLED, false)

    fun setEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_ENABLED, enabled).apply()
    }

    fun mode(context: Context): String =
        LocationRecordRules.normalizeMode(prefs(context).getString(KEY_MODE, null))

    fun setMode(context: Context, mode: String) {
        prefs(context).edit().putString(KEY_MODE, LocationRecordRules.normalizeMode(mode)).apply()
    }

    /** 서비스가 다시 떠도 정지 중이었는지 이어 간다. 모르는 값은 움직이는 중. */
    fun phase(context: Context): LocationRecordRules.Phase {
        val name = prefs(context).getString(KEY_PHASE, null)
        return LocationRecordRules.Phase.values().firstOrNull { it.name == name }
            ?: LocationRecordRules.Phase.MOVING
    }

    fun setPhase(context: Context, phase: LocationRecordRules.Phase) {
        prefs(context).edit().putString(KEY_PHASE, phase.name).apply()
    }

    /** 지금 정지(`STILL`)에 들어간 시각(epoch millis). 모르면 0. 채널 `status` 가 너무 긴 정지를 본다. */
    fun stillSince(context: Context): Long = prefs(context).getLong(KEY_STILL_SINCE, 0L)

    fun setStillSince(context: Context, ms: Long) {
        prefs(context).edit().putLong(KEY_STILL_SINCE, ms).apply()
    }

    /**
     * inbox 에 마지막으로 남긴 점. 서비스가 다시 떠도 기록 끝 표시를 남길 수 있게 prefs 에 둔다
     * (SharedPreferences 가 메모리에도 들고 있다). 끝 표시를 남기면 지운다 — 한 번만 남긴다.
     */
    fun lastSaved(context: Context): LocationRecordRules.SavedPoint? {
        val p = prefs(context)
        if (!p.contains(KEY_LAST_T)) return null
        return LocationRecordRules.SavedPoint(
            timeMs = p.getLong(KEY_LAST_T, 0L),
            lat = Double.fromBits(p.getLong(KEY_LAST_LAT, 0L)),
            lng = Double.fromBits(p.getLong(KEY_LAST_LNG, 0L)),
            accuracyM = if (p.contains(KEY_LAST_ACC)) Double.fromBits(p.getLong(KEY_LAST_ACC, 0L)) else null,
        )
    }

    fun setLastSaved(context: Context, point: LocationRecordRules.SavedPoint) {
        prefs(context).edit().apply {
            putLong(KEY_LAST_T, point.timeMs)
            putLong(KEY_LAST_LAT, point.lat.toRawBits())
            putLong(KEY_LAST_LNG, point.lng.toRawBits())
            if (point.accuracyM == null) remove(KEY_LAST_ACC) else putLong(KEY_LAST_ACC, point.accuracyM.toRawBits())
        }.apply()
    }

    fun clearLastSaved(context: Context) {
        prefs(context).edit().remove(KEY_LAST_T).remove(KEY_LAST_LAT).remove(KEY_LAST_LNG).remove(KEY_LAST_ACC)
            .apply()
    }
}
