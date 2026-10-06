package com.gdelataillade.alarm.services

import com.gdelataillade.alarm.generated.AlarmSettingsWire
import com.gdelataillade.alarm.generated.NotificationSettingsWire
import com.gdelataillade.alarm.generated.VolumeSettingsWire
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
 * Fork: the order in which a ring tries its sounds.
 *
 * The primary path is the alarm's own sound, where null means the device
 * default alarm sound. When that cannot be played -- a copied file that is
 * gone, a codec the device refuses, a device whose default alarm is "none" --
 * the ring retries with the fallback rather than ringing silently.
 */
class AudioFallbackTest {
    private val beep = "assets/alarm/default.wav"
    private val copied = "/data/user/0/app/app_flutter/alarm_sounds/abc.ogg"

    @Test
    fun `the device default alone when there is no fallback`() {
        assertEquals(listOf<String?>(null), audioCandidates(null, null))
    }

    @Test
    fun `the device default, then the fallback`() {
        assertEquals(listOf<String?>(null, beep), audioCandidates(null, beep))
    }

    @Test
    fun `a file alone when there is no fallback`() {
        assertEquals(listOf<String?>(copied), audioCandidates(copied, null))
    }

    @Test
    fun `a file, then the fallback`() {
        assertEquals(listOf<String?>(copied, beep), audioCandidates(copied, beep))
    }

    @Test
    fun `a fallback equal to the primary is tried once`() {
        assertEquals(listOf<String?>(beep), audioCandidates(beep, beep))
    }

    private fun settings(fallback: String?) = AlarmSettings(
        id = 42,
        dateTime = Date(1_786_086_270_000),
        assetAudioPath = copied,
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
        androidFallbackAudioPath = fallback,
    )

    @Test
    fun `the fallback survives storage`() {
        val json = Json.encodeToString(settings(fallback = beep))

        assertEquals(beep, Json.decodeFromString<AlarmSettings>(json).androidFallbackAudioPath)
        assertEquals(beep, AlarmSettings.fromJson(json).androidFallbackAudioPath)
    }

    @Test
    fun `an alarm stored before the fallback existed has none`() {
        // Json omits a property equal to its declared default, so this is
        // exactly what an alarm written before the fork looks like.
        val json = Json.encodeToString(settings(fallback = null))

        assertFalse(json.contains("androidFallbackAudioPath"))
        assertNull(Json.decodeFromString<AlarmSettings>(json).androidFallbackAudioPath)
        assertNull(AlarmSettings.fromJson(json).androidFallbackAudioPath)
    }

    @Test
    fun `the legacy parser reads an explicit null as none`() {
        // JsonNull's content is the string "null", which must not become a path.
        val json = Json.encodeToString(settings(fallback = beep))
            .replace("\"androidFallbackAudioPath\":\"$beep\"", "\"androidFallbackAudioPath\":null")

        assertNull(AlarmSettings.fromJson(json).androidFallbackAudioPath)
    }

    @Test
    fun `the fallback crosses the wire`() {
        val wire = AlarmSettingsWire(
            id = 42,
            millisecondsSinceEpoch = 1_786_086_270_000,
            assetAudioPath = copied,
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
            androidFallbackAudioPath = beep,
            androidSilentWhenRingerMuted = false,
            snoozeCount = 0,
        )

        assertEquals(beep, AlarmSettings.fromWire(wire).androidFallbackAudioPath)
    }
}
