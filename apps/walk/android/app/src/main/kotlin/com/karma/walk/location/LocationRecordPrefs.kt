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
}
