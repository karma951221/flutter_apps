package com.karma.walk

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext

/**
 * 하루 한 번 알람 예약을 다시 채운다. 예약은 앞으로 14일만 걸어 두므로(`AlarmUseCase.sync`),
 * 앱을 2주 넘게 열지 않아도 반복 알람이 끊기지 않게 한다. 실행은 [BackgroundDispatcher] 가 맡는다.
 *
 * 결과와 상관없이 성공으로 끝낸다 — 실패해도 다음 날 다시 돌고, 재시도 백오프로 쌓지 않는다.
 */
class DailyAlarmSyncWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val reason = withContext(Dispatchers.Main.immediate) {
            suspendCancellableCoroutine { continuation ->
                val handle = BackgroundDispatcher.dispatch(
                    applicationContext,
                    BackgroundJob.resync,
                    TIMEOUT_MS,
                ) { _, reason ->
                    if (continuation.isActive) continuation.resume(reason)
                }
                continuation.invokeOnCancellation {
                    Handler(Looper.getMainLooper()).post { handle.cancel() }
                }
            }
        }
        Log.i(TAG, "daily sync: $reason")
        return Result.success()
    }

    companion object {
        private const val TAG = "WalkDailySync"
        private const val TIMEOUT_MS = 60_000L
        const val UNIQUE_NAME = "walk.alarm.dailySync"

        /** 24시간 주기 · 첫 실행은 하루 뒤. 이미 걸려 있으면 그대로 둔다(`KEEP`) — 앱을 열 때마다 부른다. */
        fun enqueue(context: Context) {
            val request = PeriodicWorkRequestBuilder<DailyAlarmSyncWorker>(1, TimeUnit.DAYS)
                .setInitialDelay(1, TimeUnit.DAYS)
                .build()
            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(UNIQUE_NAME, ExistingPeriodicWorkPolicy.KEEP, request)
        }
    }
}
