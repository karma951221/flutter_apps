package com.karma.walk

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
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
 *
 * `pickFile` 은 사용자가 고른 오디오 파일을 같은 길로 곧바로 복사한다 — 원본을 지워도 알람이 울리게
 * 영구 URI 권한은 받지 않는다. 문서 선택기는 액티비티 결과라 [openDocument] 로 [MainActivity] 에
 * 띄워 달라 하고, 결과는 [onDocumentPicked] 로 받는다.
 */
class AlarmSoundsChannel(
    private val context: Context,
    messenger: BinaryMessenger,
    private val openDocument: () -> Unit,
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

    /** 문서 선택기를 띄우고 결과를 기다리는 호출. 한 번에 하나만 받는다. */
    private var pendingPick: PendingPick? = null

    private class PendingPick(val result: MethodChannel.Result, val fallbackTitle: String)

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
            "pickFile" -> pickFile(call.argument<String>("fallbackTitle"), result)
            else -> result.notImplemented()
        }
    }

    private fun pickFile(fallbackTitle: String?, result: MethodChannel.Result) {
        if (fallbackTitle == null) {
            result.error("bad_args", "fallbackTitle is required", null)
            return
        }
        if (pendingPick != null) {
            result.error("busy", "a file pick is already in progress", null)
            return
        }
        pendingPick = PendingPick(result, fallbackTitle)
        try {
            openDocument()
        } catch (e: Exception) {
            pendingPick = null
            result.error("failed", e.message, null)
        }
    }

    /** [MainActivity] 가 문서 선택기 결과를 넘긴다. [uri] 가 null 이면 취소. */
    fun onDocumentPicked(uri: Uri?) {
        val pending = pendingPick ?: return
        pendingPick = null
        if (uri == null) {
            pending.result.success(null)
            return
        }
        background(pending.result) { importPicked(uri, pending.fallbackTitle) }
    }

    /** 이름 · 크기를 읽고, 상한 안이면 앱 저장소로 복사한다. */
    private fun importPicked(uri: Uri, fallbackTitle: String): Map<String, String> {
        var displayName: String? = null
        var size: Long? = null
        context.contentResolver
            .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameColumn = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val sizeColumn = cursor.getColumnIndex(OpenableColumns.SIZE)
                    if (nameColumn >= 0 && !cursor.isNull(nameColumn)) displayName = cursor.getString(nameColumn)
                    if (sizeColumn >= 0 && !cursor.isNull(sizeColumn)) size = cursor.getLong(sizeColumn)
                }
            }
        if (AlarmFileRules.isTooLarge(size)) throw AlarmFileTooLargeException()
        val path = importRingtone(uri, maxBytes = AlarmFileRules.MAX_BYTES)
        return mapOf("title" to AlarmFileRules.titleOf(displayName, fallbackTitle), "path" to path)
    }

    /** 엔진이 내려갈 때 부른다. 미리 듣기를 해제하고 채널을 뗀다. */
    fun dispose() {
        stopPreview()
        // 엔진이 내려가면 기다리던 Dart 쪽도 없다 — 늦게 온 결과는 버린다.
        pendingPick = null
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

    /**
     * 복사 후 재생 가능한지 검증한다. 같은 uri 는 같은 경로라 여러 알람이 한 복사본을 함께 쓴다.
     * 그래서 임시 파일에 복사 · 검증한 뒤에만 바꾸고([replaceVerified]), 실패하면 임시 파일만 지운다.
     * [maxBytes] 를 주면 복사 중 그보다 커지는 순간 멈춘다([AlarmFileTooLargeException]).
     */
    private fun importRingtone(uri: Uri, maxBytes: Long? = null): String {
        val folder = File(context.getDir("flutter", Context.MODE_PRIVATE), FOLDER).apply { mkdirs() }
        val extension =
            context.contentResolver.getType(uri)
                ?.let { MimeTypeMap.getSingleton().getExtensionFromMimeType(it) }
                ?: DEFAULT_EXTENSION
        val target = File(folder, "${hash(uri.toString())}.$extension")
        replaceVerified(
            target,
            write = { temp ->
                val input = context.contentResolver.openInputStream(uri)
                    ?: throw IllegalStateException("cannot open $uri")
                input.use { source ->
                    temp.outputStream().use { target ->
                        if (maxBytes == null) {
                            source.copyTo(target)
                        } else {
                            AlarmFileRules.copyBounded(source, target, maxBytes)
                        }
                    }
                }
            },
            verify = { temp ->
                val check = MediaPlayer()
                try {
                    check.setDataSource(temp.absolutePath)
                    check.prepare()
                } finally {
                    check.release()
                }
            },
        )
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
            } catch (e: AlarmFileTooLargeException) {
                main.post { result.error("too_large", e.message, null) }
            } catch (e: Exception) {
                main.post { result.error("failed", e.message, null) }
            }
        }
    }
}
