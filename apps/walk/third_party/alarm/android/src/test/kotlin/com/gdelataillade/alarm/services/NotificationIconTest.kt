package com.gdelataillade.alarm.services

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Fork: which small icon the alarm notification uses.
 *
 * The original falls back to the application icon. When that is an
 * adaptive-icon mipmap (only in mipmap-anydpi-v26), the status bar shows a
 * solid blob, and Android 8.0 can fail to post the notification. Alarms set
 * without an icon name, or with a name that no longer resolves, fall back to
 * the platform's monochrome alarm drawable instead.
 */
class NotificationIconTest {
    private val found = 0x7f080001
    private val lookup: (String) -> Int = { name -> if (name == "ic_stat_alarm") found else 0 }

    @Test
    fun `a requested name that resolves is used`() {
        assertEquals(found, smallIconResId("ic_stat_alarm", lookup))
    }

    @Test
    fun `no requested name falls back to the platform alarm drawable`() {
        assertEquals(android.R.drawable.ic_lock_idle_alarm, smallIconResId(null, lookup))
    }

    @Test
    fun `a name that does not resolve falls back to the platform alarm drawable`() {
        assertEquals(android.R.drawable.ic_lock_idle_alarm, smallIconResId("renamed", lookup))
    }
}
