package com.karma.walk

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * `com.karma.walk/backup_file` — 백업 파일 저장(위치 고르기) · 열기 · 앱 재시작 · 여유 공간.
 *
 * `file_picker` 의 `saveFile` 은 바이트 배열 전체를 받아 큰 백업에 쓸 수 없다. Dart 가 앱 캐시에 만든
 * 파일을 `ACTION_CREATE_DOCUMENT` 로 받은 URI 에 스트림으로 복사하고, 열기는 `ACTION_OPEN_DOCUMENT` 로
 * 고른 파일을 캐시 `backup_import/` 에 스트림으로 복사해 그 경로를 돌려준다(사본은 Dart 가 지운다).
 * 문서 창은 액티비티 결과라 [launch] 로 [MainActivity] 에 띄워 달라 하고, 결과는 [onDocument] 로 받는다.
 * 복사는 메인 스레드를 막지 않게 별도 스레드에서 한다.
 */
class BackupFileChannel(
    private val context: Context,
    messenger: BinaryMessenger,
    private val launch: (Intent) -> Unit,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "com.karma.walk/backup_file"
        private const val IMPORT_FOLDER = "backup_import"
        private const val IMPORT_NAME = "picked"
    }

    private val channel = MethodChannel(messenger, NAME)
    private val worker: ExecutorService = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** 문서 창 결과를 기다리는 호출. 한 번에 하나만 받는다. */
    private val pending = PendingSlot<Pending>()

    private sealed class Pending(val result: MethodChannel.Result) {
        /** 저장: [source] 를 고른 위치에 복사한다. 취소면 false. */
        class Save(result: MethodChannel.Result, val source: File) : Pending(result)

        /** 열기: 고른 파일을 캐시에 복사한다. 취소면 null. */
        class Open(result: MethodChannel.Result) : Pending(result)

        fun cancel() = result.success(if (this is Save) false else null)
    }

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveAs" -> {
                val path = call.argument<String>("path")
                val name = call.argument<String>("name")
                val mime = call.argument<String>("mime")
                if (path == null || name == null || mime == null) {
                    result.error("bad_args", "path, name, mime are required", null)
                    return
                }
                start(
                    Pending.Save(result, File(path)),
                    Intent(Intent.ACTION_CREATE_DOCUMENT)
                        .addCategory(Intent.CATEGORY_OPENABLE)
                        .setType(mime)
                        .putExtra(Intent.EXTRA_TITLE, name),
                )
            }
            "open" ->
                // 영구 권한(takePersistableUriPermission)은 받지 않는다 — 고르자마자 복사한다.
                start(
                    Pending.Open(result),
                    Intent(Intent.ACTION_OPEN_DOCUMENT)
                        .addCategory(Intent.CATEGORY_OPENABLE)
                        .setType("*/*"),
                )
            "restart" -> restart(result)
            // 백업 작업 폴더(문서 폴더)와 앱 캐시는 같은 데이터 파티션에 있다.
            "freeBytes" -> result.success(StatFs(context.cacheDir.path).availableBytes)
            else -> result.notImplemented()
        }
    }

    private fun start(next: Pending, intent: Intent) {
        // Dart 화면이 동시 호출을 막으므로 남아 있는 것은 결과를 잃은 옛 호출이다 — 취소로 끝내고 새로 띄운다.
        pending.replace(next)?.cancel()
        try {
            launch(intent)
        } catch (e: Exception) {
            pending.clear()
            next.result.error("failed", e.message, null)
        }
    }

    /** [MainActivity] 가 문서 창 결과를 넘긴다. [uri] 가 null 이면 취소. */
    fun onDocument(uri: Uri?) {
        val waiting = pending.take() ?: return
        if (uri == null) {
            waiting.cancel()
            return
        }
        when (waiting) {
            is Pending.Save -> background(waiting.result) { save(waiting.source, uri) }
            is Pending.Open -> background(waiting.result) { copyToCache(uri) }
        }
    }

    /** 실패하면 반쯤 쓴 문서를 지운다(지원하지 않는 제공자면 남는다). */
    private fun save(source: File, target: Uri): Boolean {
        try {
            val output = context.contentResolver.openOutputStream(target, "w")
                ?: throw IOException("cannot open $target")
            source.inputStream().use { input -> output.use { BackupFileRules.copyStream(input, it) } }
            return true
        } catch (e: Exception) {
            try {
                DocumentsContract.deleteDocument(context.contentResolver, target)
            } catch (_: Exception) {
                // 지울 수 없으면 그대로 둔다 — 원래 오류를 알린다.
            }
            throw e
        }
    }

    /** 이전 사본을 지우고 새로 복사한다. 실패하면 반쯤 쓴 사본을 지운다. */
    private fun copyToCache(uri: Uri): String {
        val folder = File(context.cacheDir, IMPORT_FOLDER)
        folder.deleteRecursively()
        folder.mkdirs()
        val target = File(folder, IMPORT_NAME)
        try {
            val input = context.contentResolver.openInputStream(uri)
                ?: throw IOException("cannot open $uri")
            input.use { source -> target.outputStream().use { BackupFileRules.copyStream(source, it) } }
            return target.absolutePath
        } catch (e: Exception) {
            target.delete()
            throw e
        }
    }

    /** 런처 액티비티를 새 태스크로 띄우고 지금 프로세스를 끝낸다 — 복원한 DB · 설정을 처음부터 읽게. */
    private fun restart(result: MethodChannel.Result) {
        val launcher = context.packageManager.getLaunchIntentForPackage(context.packageName)?.component
        if (launcher == null) {
            result.error("failed", "no launcher activity", null)
            return
        }
        context.startActivity(Intent.makeRestartActivityTask(launcher))
        Runtime.getRuntime().exit(0)
    }

    /** 엔진이 내려갈 때 부른다. 늦게 온 결과는 버리고 채널을 뗀다. */
    fun dispose() {
        pending.clear()
        channel.setMethodCallHandler(null)
        worker.shutdown()
    }

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        worker.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Exception) {
                val code = if (isNoSpace(e)) "no_space" else "failed"
                main.post { result.error(code, e.message, null) }
            }
        }
    }

    /** 저장 공간 부족(ENOSPC). Dart 가 따로 안내한다. */
    private fun isNoSpace(e: Throwable): Boolean =
        generateSequence(e) { it.cause }.any { it.message?.contains("ENOSPC") == true }
}
