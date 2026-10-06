package com.karma.walk

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.webkit.MimeTypeMap
import io.flutter.FlutterInjector
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * `walk/alarm_sounds` — 기기 알람음 목록 · 미리 듣기 · 앱 저장소 복사.
 *
 * `alarm` 패키지는 `content://` 를 못 읽으므로 고른 기기 알람음을 `app_flutter/alarm_sounds/` 에
 * 복사하고 그 절대 경로로 울린다. 목록 읽기와 복사는 메인 스레드를 막지 않게 별도 스레드에서 한다.
 */
class AlarmSoundsChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "walk/alarm_sounds"
        private const val FOLDER = "alarm_sounds"
        private const val DEFAULT_EXTENSION = "ogg"
    }

    private val channel = MethodChannel(messenger, NAME)
    private val worker: ExecutorService = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** 미리 듣기 재생기. 하나만 둔다 — 새로 틀면 앞의 것을 해제한다. */
    private var player: MediaPlayer? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "list" -> background(result) { listRingtones() }
            "preview" -> preview(call.argument<String>("kind"), call.argument<String>("value"), result)
            "stopPreview" -> {
                stopPreview()
                result.success(null)
            }
            "import" -> {
                val uri = call.argument<String>("uri")
                if (uri == null) {
                    result.error("bad_args", "uri is required", null)
                } else {
                    background(result) { importRingtone(Uri.parse(uri)) }
                }
            }
            else -> result.notImplemented()
        }
    }

    /** 엔진이 내려갈 때 부른다. 미리 듣기를 해제하고 채널을 뗀다. */
    fun dispose() {
        stopPreview()
        channel.setMethodCallHandler(null)
        worker.shutdown()
    }

    private fun listRingtones(): List<Map<String, String>> {
        val manager = RingtoneManager(context).apply { setType(RingtoneManager.TYPE_ALARM) }
        val cursor = manager.cursor
        val rows = mutableListOf<Map<String, String>>()
        try {
            while (cursor.moveToNext()) {
                val title = cursor.getString(RingtoneManager.TITLE_COLUMN_INDEX) ?: continue
                val uri = manager.getRingtoneUri(cursor.position) ?: continue
                rows += mapOf("title" to title, "uri" to uri.toString())
            }
        } finally {
            cursor.close()
        }
        return rows
    }

    private fun preview(kind: String?, value: String?, result: MethodChannel.Result) {
        stopPreview()
        val next = MediaPlayer()
        try {
            next.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            when (kind) {
                "system" -> next.setDataSource(context, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM))
                "asset" -> {
                    val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(value!!)
                    context.assets.openFd(key).use { fd ->
                        next.setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
                    }
                }
                "uri" -> next.setDataSource(context, Uri.parse(value!!))
                else -> throw IllegalArgumentException("unknown kind: $kind")
            }
            next.isLooping = true
            next.prepare()
            next.start()
            player = next
            result.success(null)
        } catch (e: Exception) {
            next.release()
            result.error("preview_failed", e.message, null)
        }
    }

    private fun stopPreview() {
        player?.let {
            try {
                it.stop()
            } catch (_: IllegalStateException) {
                // 준비 전이면 멈출 것이 없다.
            }
            it.release()
        }
        player = null
    }

    /** 복사 후 재생 가능한지 검증한다. 실패하면 복사본을 지우고 던진다. 같은 uri 는 덮어쓴다. */
    private fun importRingtone(uri: Uri): String {
        val folder = File(context.getDir("flutter", Context.MODE_PRIVATE), FOLDER).apply { mkdirs() }
        val extension =
            context.contentResolver.getType(uri)
                ?.let { MimeTypeMap.getSingleton().getExtensionFromMimeType(it) }
                ?: DEFAULT_EXTENSION
        val target = File(folder, "${hash(uri.toString())}.$extension")
        try {
            val input = context.contentResolver.openInputStream(uri)
                ?: throw IllegalStateException("cannot open $uri")
            input.use { source -> target.outputStream().use { source.copyTo(it) } }
            val check = MediaPlayer()
            try {
                check.setDataSource(target.absolutePath)
                check.prepare()
            } finally {
                check.release()
            }
        } catch (e: Exception) {
            target.delete()
            throw e
        }
        return target.absolutePath
    }

    private fun hash(text: String): String =
        MessageDigest.getInstance("SHA-1")
            .digest(text.toByteArray())
            .joinToString("") { "%02x".format(it) }
            .take(16)

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        worker.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("failed", e.message, null) }
            }
        }
    }
}
