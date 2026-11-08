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

    enum class Phase { MOVING, STILL }

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
