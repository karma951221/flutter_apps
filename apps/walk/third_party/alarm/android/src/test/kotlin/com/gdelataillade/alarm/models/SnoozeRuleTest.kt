package com.gdelataillade.alarm.models

import com.gdelataillade.alarm.generated.AlarmSettingsWire
import com.gdelataillade.alarm.generated.NotificationSettingsWire
import com.gdelataillade.alarm.generated.VolumeSettingsWire
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Date

/**
 * Fork: how a snooze counts itself.
 *
 * Every snooze moves the alarm and adds one to [AlarmSettings.snoozeCount].
 * Once the count reaches [AlarmSettings.androidSnoozeLimit], the next ring
 * offers no snooze at all: no duration and no button. No limit snoozes forever.
 */
class SnoozeRuleTest {
    private val fiveMinutes = 300_000L

    private fun settings(limit: Int? = null, count: Int = 0) = AlarmSettings(
        id = 42,
        dateTime = Date(1_786_086_270_000),
        assetAudioPath = null,
        volumeSettings = VolumeSettings(
            volume = 0.8,
            fadeDuration = null,
            fadeSteps = emptyList(),
            volumeEnforced = false,
        ),
        notificationSettings = NotificationSettings(
            title = "Title",
            body = "Body",
            androidSnoozeButton = "Snooze",
        ),
        loopAudio = true,
        vibrate = true,
        warningNotificationOnKill = true,
        androidFullScreenIntent = true,
        androidSnoozeDurationMillis = fiveMinutes,
        snoozeCount = count,
        androidSnoozeLimit = limit,
    )

    @Test
    fun `a snooze moves the alarm and counts`() {
        val next = Date(1_786_086_570_000)

        val snoozed = settings().nextAfterSnooze(next)

        assertEquals(next, snoozed.dateTime)
        assertEquals(1, snoozed.snoozeCount)
    }

    @Test
    fun `without a limit the alarm keeps snoozing`() {
        var current = settings()
        repeat(10) { current = current.nextAfterSnooze(Date(current.dateTime.time + fiveMinutes)) }

        assertEquals(10, current.snoozeCount)
        assertTrue(current.canSnooze)
        assertEquals(fiveMinutes, current.androidSnoozeDurationMillis)
        assertEquals("Snooze", current.notificationSettings.androidSnoozeButton)
    }

    @Test
    fun `a limit of three leaves snooze on for the first two`() {
        val first = settings(limit = 3).nextAfterSnooze(Date(1))
        val second = first.nextAfterSnooze(Date(2))

        assertTrue(first.canSnooze)
        assertTrue(second.canSnooze)
        assertEquals("Snooze", second.notificationSettings.androidSnoozeButton)
    }

    @Test
    fun `a limit of three removes snooze after the third`() {
        val third = settings(limit = 3, count = 2).nextAfterSnooze(Date(3))

        assertEquals(3, third.snoozeCount)
        assertFalse(third.canSnooze)
        assertNull(third.androidSnoozeDurationMillis)
        assertNull(third.notificationSettings.androidSnoozeButton)
    }

    @Test
    fun `the count and limit survive storage`() {
        val json = Json.encodeToString(settings(limit = 3, count = 2))

        for (restored in listOf(
            Json.decodeFromString<AlarmSettings>(json),
            AlarmSettings.fromJson(json),
        )) {
            assertEquals(2, restored.snoozeCount)
            assertEquals(3, restored.androidSnoozeLimit)
        }
    }

    @Test
    fun `an alarm stored before counting existed has no count and no limit`() {
        // Json omits a property equal to its declared default, so this is
        // exactly what an alarm written before the fork looks like.
        val json = Json.encodeToString(settings())

        assertFalse(json.contains("snoozeCount"))
        assertFalse(json.contains("androidSnoozeLimit"))
        assertEquals(0, AlarmSettings.fromJson(json).snoozeCount)
        assertNull(AlarmSettings.fromJson(json).androidSnoozeLimit)
    }

    @Test
    fun `the count and limit cross the wire`() {
        val wire = AlarmSettingsWire(
            id = 42,
            millisecondsSinceEpoch = 1_786_086_270_000,
            assetAudioPath = null,
            volumeSettings = VolumeSettingsWire(
                volume = 0.8,
                fadeDurationMillis = null,
                fadeSteps = emptyList(),
                volumeEnforced = false,
                showSystemUI = true,
            ),
            notificationSettings = NotificationSettingsWire(
                title = "Title",
                body = "Body",
                keepNotificationAfterAlarmEnds = false,
                androidStopAlarmOnDismiss = true,
            ),
            loopAudio = true,
            vibrate = true,
            warningNotificationOnKill = true,
            androidFullScreenIntent = true,
            allowAlarmOverlap = false,
            allowSameSecondScheduling = false,
            iOSBackgroundAudio = true,
            androidStopAlarmOnTermination = true,
            preferConnectedAudioDevice = false,
            androidAlarmClock = true,
            androidSilentWhenRingerMuted = false,
            androidAutoStopAfterMillis = 600_000,
            androidSnoozeLimit = 3,
            snoozeCount = 2,
        )

        val settings = AlarmSettings.fromWire(wire)

        assertEquals(2, settings.snoozeCount)
        assertEquals(3, settings.androidSnoozeLimit)
        assertEquals(600_000L, settings.androidAutoStopAfterMillis)
    }
}
