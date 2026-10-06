package com.gdelataillade.alarm.services

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator

class VibrationService(context: Context) {
    private val vibrator: Vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator

    fun startVibrating(pattern: LongArray, repeat: Int) {
        // Fork: tag the vibration as an alarm, so a phone on vibrate or silent
        // does not suppress it the way it may a plain (touch/notification) one.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val vibrationEffect = VibrationEffect.createWaveform(pattern, repeat)
            vibrator.vibrate(
                vibrationEffect,
                VibrationAttributes.createForUsage(VibrationAttributes.USAGE_ALARM)
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Use VibrationEffect for API 26 and above
            val vibrationEffect = VibrationEffect.createWaveform(pattern, repeat)
            @Suppress("DEPRECATION")
            vibrator.vibrate(
                vibrationEffect,
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
        } else {
            // Use the older vibrate method for below API 26
            vibrator.vibrate(pattern, repeat)
        }
    }

    fun stopVibrating() {
        vibrator.cancel()
    }
}
