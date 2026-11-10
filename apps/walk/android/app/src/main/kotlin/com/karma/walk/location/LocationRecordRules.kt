package com.karma.walk.location

/**
 * 위치 기록의 순수 규칙. Play Services · Android 를 import 하지 않는다 — JVM 테스트
 * (`LocationRecordRulesTest`)가 클래스를 그대로 불러온다. 우선순위는 `Priority` 상수의 숫자 값.
 */
object LocationRecordRules {
    const val MODE_NORMAL = "normal"
    const val MODE_DENSE = "dense"

    const val STATE_OFF = "off"
    const val STATE_RUNNING = "running"
    const val STATE_BLOCKED = "blocked"

    /** `Priority.PRIORITY_HIGH_ACCURACY` */
    private const val PRIORITY_HIGH_ACCURACY = 100

    /** `Priority.PRIORITY_BALANCED_POWER_ACCURACY` */
    private const val PRIORITY_BALANCED_POWER_ACCURACY = 102

    /** `Priority.PRIORITY_PASSIVE` — 스스로 위치를 켜지 않고 다른 앱이 받은 위치만 얻는다. */
    private const val PRIORITY_PASSIVE = 105

    data class Request(
        val priority: Int,
        val intervalMs: Long,
        val minDistanceM: Float,
        val maxDelayMs: Long,
    )

    private val normal = Request(PRIORITY_BALANCED_POWER_ACCURACY, 180_000L, 50f, 600_000L)
    private val dense = Request(PRIORITY_HIGH_ACCURACY, 5_000L, 10f, 0L)

    /** 모르는 모드는 평소로 본다. */
    fun normalizeMode(mode: String?): String = if (mode == MODE_DENSE) MODE_DENSE else MODE_NORMAL

    /**
     * 정지(`STILL`) 중에 거는 감시 요청. 저전력(passive) · 15분 — STILL 이탈 전환을 놓쳐도 움직임을
     * 알아챈다([watchdogShouldResume]).
     */
    val watchdogRequest = Request(PRIORITY_PASSIVE, 900_000L, 0f, 0L)

    /** 정지 점에서 이만큼까지는 같은 자리로 본다(Dart `TrackAnalyzer.stayRadiusM` 과 같다). */
    const val STILL_RADIUS_M = 100f

    /**
     * 감시 위치가 정지 점에서 100m + 두 점의 정확도(모르면 0)보다 멀면 STILL 이탈일 수 있다. passive
     * 위치는 기지국 · 와이파이로 수백 m 튈 수 있어 정확도만큼은 봐준다. 확인은 [stillResumeIsStillThere].
     */
    fun watchdogShouldResume(distanceM: Float, accuracyM: Float?, anchorAccuracyM: Float?): Boolean =
        distanceM > STILL_RADIUS_M + (accuracyM ?: 0f) + (anchorAccuracyM ?: 0f)

    /**
     * 정지를 끝내려 할 때(감시가 움직임을 봤거나 정지가 6시간을 넘김) 새로 잡은 점이 정지 점에서 100m
     * 안이면 아직 그 자리 — `still` 점(심장박동)으로 남기고 정지를 이어 간다.
     */
    fun stillResumeIsStillThere(distanceM: Float): Boolean = distanceM <= STILL_RADIUS_M

    /** 정지가 이보다 길면 다음 `status`(앱이 앞에 올 때) 에 위치 요청을 다시 건다. */
    const val STILL_MAX_MS = 6 * 60 * 60_000L

    /** 시작 시각이 미래(시계가 뒤로 감)거나 모르면(0) 너무 오래된 것으로 본다 — 갇히지 않는 쪽. */
    fun stillTooLong(sinceMs: Long, nowMs: Long): Boolean =
        sinceMs <= 0L || sinceMs > nowMs || nowMs - sinceMs > STILL_MAX_MS

    /** 위치 요청(`requestLocationUpdates`)이 권한 밖의 이유로 실패하면 이만큼 뒤에 다시 건다. */
    const val UPDATES_RETRY_MS = 60_000L

    /** 재시도는 실패한 그 요청이 아직 최신이고(그 사이 멈추거나 다시 걸지 않음) 서비스가 살아 있을 때만. */
    fun shouldRetryUpdates(gen: Int, currentGen: Int, destroyed: Boolean): Boolean =
        !destroyed && gen == currentGen

    fun requestFor(mode: String): Request = if (normalizeMode(mode) == MODE_DENSE) dense else normal

    /** 백그라운드 위치 권한이 없으면 부팅 직후 서비스를 띄워도 점을 못 받는다. */
    fun shouldRestartOnBoot(enabled: Boolean, hasBackgroundPermission: Boolean): Boolean =
        enabled && hasBackgroundPermission

    /** 켜짐으로 저장됐는데 권한 · 위치 서비스가 없으면 `blocked`(Dart 지도 칩 "기록 꺼짐 · 권한 필요"). */
    fun stateOf(enabled: Boolean, hasBackgroundPermission: Boolean, locationOn: Boolean): String = when {
        !enabled -> STATE_OFF
        hasBackgroundPermission && locationOn -> STATE_RUNNING
        else -> STATE_BLOCKED
    }

    /**
     * 앱이 앞에 올 때(`status` · `start`) 켜짐 + 권한인데 서비스가 죽어 있으면(sticky 재시작 실패 ·
     * 제조사 정리) 다시 띄운다.
     */
    fun shouldRevive(enabled: Boolean, hasBackgroundPermission: Boolean, serviceRunning: Boolean): Boolean =
        enabled && hasBackgroundPermission && !serviceRunning

    /** `lastLocation` 대체 점으로 쓸 수 있는 최대 나이. */
    const val FALLBACK_MAX_AGE_MS = 5 * 60_000L

    /** 지금 위치를 못 잡았을 때 마지막 위치는 5분 안의 것만 쓴다(시계가 뒤로 간 미래 시각도 버린다). */
    fun isFreshFallback(fixTimeMs: Long, nowMs: Long): Boolean =
        fixTimeMs <= nowMs && nowMs - fixTimeMs <= FALLBACK_MAX_AGE_MS

    enum class Phase { MOVING, STILL }

    /**
     * 서비스 인스턴스가 시작할 때의 단계. 새 인스턴스는 늘 움직이는 중으로 시작한다 — 프로세스가 죽은
     * 사이의 전환 이벤트는 버려지므로 저장된 STILL 을 믿으면 위치 요청 없이 갇힌다. 다시 멈추는 건
     * 새 `STILL` 진입이 한다. 같은 인스턴스 안에서는 저장된 단계를 이어 간다.
     */
    fun phaseOnServiceStart(newInstance: Boolean, saved: Phase): Phase =
        if (newInstance) Phase.MOVING else saved

    sealed interface Action {
        /** 지금 위치 한 점을 `still = 1` 로 남기고 위치 요청을 멈춘다. */
        object Pause : Action

        /** 위치 요청을 다시 걸고 곧바로 한 점을 잡는다. */
        object ResumeAndFix : Action

        object None : Action
    }

    /**
     * Activity Transition `STILL` 진입(`enteredStill`) · 이탈을 받아 다음 단계와 할 일을 정한다.
     * 정지 감지는 평소 모드 + 활동 인식 권한이 있을 때만 — 아니면 언제나 움직이는 중으로 본다.
     * 같은 단계로 다시 들어오는 중복 이벤트는 아무것도 하지 않는다.
     */
    fun onTransition(mode: String, phase: Phase, enteredStill: Boolean, stillDetection: Boolean): Pair<Phase, Action> {
        if (normalizeMode(mode) != MODE_NORMAL || !stillDetection) return Phase.MOVING to Action.None
        val next = if (enteredStill) Phase.STILL else Phase.MOVING
        if (next == phase) return phase to Action.None
        return next to if (next == Phase.STILL) Action.Pause else Action.ResumeAndFix
    }
}
