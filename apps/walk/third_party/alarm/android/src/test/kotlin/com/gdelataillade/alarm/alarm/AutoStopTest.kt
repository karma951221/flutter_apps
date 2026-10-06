package com.gdelataillade.alarm.alarm

import com.gdelataillade.alarm.models.AlarmSettings
import com.gdelataillade.alarm.models.NotificationSettings
import com.gdelataillade.alarm.models.VolumeSettings
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Test
import java.util.Date

/**
 * Fork: how long a ring lasts before the service stops it on its own.
 *
 * Measured from when the ring starts. Null, zero or negative never stops.
 */
class AutoStopTest {
    private fun settings(autoStopAfterMillis: Long?) = AlarmSettings(
        id = 42,
        dateTime = Date(1_786_086_270_000),
        assetAudioPath = null,
        volumeSettings = VolumeSettings(
            volume = 0.8,
            fadeDuration = null,
            fadeSteps = emptyList(),
            volumeEnforced = false,
        ),
        notificationSettings = NotificationSettings(title = "Title", body = "Body"),
        loopAudio = true,
        vibrate = true,
        warningNotificationOnKill = true,
        androidFullScreenIntent = true,
        androidAutoStopAfterMillis = autoStopAfterMillis,
    )

    @Test
    fun `no auto stop by default`() {
        assertNull(autoStopDelayMillis(settings(null)))
    }

    @Test
    fun `ten minutes stops ten minutes after the ring starts`() {
        assertEquals(600_000L, autoStopDelayMillis(settings(600_000)))
    }

    @Test
    fun `zero or negative never stops`() {
        assertNull(autoStopDelayMillis(settings(0)))
        assertNull(autoStopDelayMillis(settings(-1)))
    }

    @Test
    fun `the delay survives storage`() {
        val json = Json.encodeToString(settings(300_000))

        assertEquals(300_000L, Json.decodeFromString<AlarmSettings>(json).androidAutoStopAfterMillis)
        assertEquals(300_000L, AlarmSettings.fromJson(json).androidAutoStopAfterMillis)
    }

    @Test
    fun `an alarm stored before auto stop existed never stops`() {
        val json = Json.encodeToString(settings(null))

        assertFalse(json.contains("androidAutoStopAfterMillis"))
        assertNull(AlarmSettings.fromJson(json).androidAutoStopAfterMillis)
    }
}
