package com.gdelataillade.alarm.alarm

import android.media.AudioManager
import com.gdelataillade.alarm.generated.AlarmSettingsWire
import com.gdelataillade.alarm.generated.NotificationSettingsWire
import com.gdelataillade.alarm.generated.VolumeSettingsWire
import com.gdelataillade.alarm.models.AlarmSettings
import com.gdelataillade.alarm.models.NotificationSettings
import com.gdelataillade.alarm.models.VolumeSettings
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Date

/**
 * Fork: whether a ring stays silent (vibration only) because the phone's
 * ringer is muted.
 *
 * Only an alarm that opted in follows the ringer, and only a ringer that is
 * not NORMAL -- vibrate or silent -- mutes it.
 */
class RingerMuteTest {
    @Test
    fun `opted in, a normal ringer still sounds`() {
        assertFalse(shouldMuteForRinger(true, AudioManager.RINGER_MODE_NORMAL))
    }

    @Test
    fun `opted in, a vibrate ringer mutes`() {
        assertTrue(shouldMuteForRinger(true, AudioManager.RINGER_MODE_VIBRATE))
    }

    @Test
    fun `opted in, a silent ringer mutes`() {
        assertTrue(shouldMuteForRinger(true, AudioManager.RINGER_MODE_SILENT))
    }

    @Test
    fun `not opted in, a normal ringer sounds`() {
        assertFalse(shouldMuteForRinger(false, AudioManager.RINGER_MODE_NORMAL))
    }

    @Test
    fun `not opted in, a vibrate ringer still sounds`() {
        assertFalse(shouldMuteForRinger(false, AudioManager.RINGER_MODE_VIBRATE))
    }

    @Test
    fun `not opted in, a silent ringer still sounds`() {
        assertFalse(shouldMuteForRinger(false, AudioManager.RINGER_MODE_SILENT))
    }

    private fun settings(silentWhenRingerMuted: Boolean) = AlarmSettings(
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
        androidSilentWhenRingerMuted = silentWhenRingerMuted,
    )

    @Test
    fun `the opt-in survives storage`() {
        val json = Json.encodeToString(settings(silentWhenRingerMuted = true))

        assertTrue(Json.decodeFromString<AlarmSettings>(json).androidSilentWhenRingerMuted)
        assertTrue(AlarmSettings.fromJson(json).androidSilentWhenRingerMuted)
    }

    @Test
    fun `an alarm stored before the opt-in existed ignores the ringer`() {
        // Json omits a property equal to its declared default, so this is
        // exactly what an alarm written before the fork looks like.
        val json = Json.encodeToString(settings(silentWhenRingerMuted = false))

        assertFalse(json.contains("androidSilentWhenRingerMuted"))
        assertFalse(Json.decodeFromString<AlarmSettings>(json).androidSilentWhenRingerMuted)
        assertFalse(AlarmSettings.fromJson(json).androidSilentWhenRingerMuted)
    }

    @Test
    fun `the opt-in crosses the wire`() {
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
            androidSilentWhenRingerMuted = true,
        )

        assertTrue(AlarmSettings.fromWire(wire).androidSilentWhenRingerMuted)
    }
}
