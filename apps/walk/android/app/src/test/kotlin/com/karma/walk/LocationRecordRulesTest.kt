package com.karma.walk

import com.karma.walk.location.LocationRecordRules
import com.karma.walk.location.LocationRecordRules.Action
import com.karma.walk.location.LocationRecordRules.Phase
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LocationRecordRulesTest {
    // ── 위치 요청 ──

    @Test
    fun `normal request is balanced every 3 minutes over 50m batched 10 minutes`() {
        val request = LocationRecordRules.requestFor("normal")

        assertEquals(102, request.priority) // Priority.PRIORITY_BALANCED_POWER_ACCURACY
        assertEquals(180_000L, request.intervalMs)
        assertEquals(50f, request.minDistanceM)
        assertEquals(600_000L, request.maxDelayMs)
    }

    @Test
    fun `dense request is high accuracy every 5 seconds over 10m without batching`() {
        val request = LocationRecordRules.requestFor("dense")

        assertEquals(100, request.priority) // Priority.PRIORITY_HIGH_ACCURACY
        assertEquals(5_000L, request.intervalMs)
        assertEquals(10f, request.minDistanceM)
        assertEquals(0L, request.maxDelayMs)
    }

    @Test
    fun `unknown mode falls back to normal`() {
        assertEquals(LocationRecordRules.requestFor("normal"), LocationRecordRules.requestFor("walking"))
    }

    // ── 재부팅 복구 ──

    @Test
    fun `boot restarts only when enabled with background permission`() {
        assertTrue(LocationRecordRules.shouldRestartOnBoot(enabled = true, hasBackgroundPermission = true))
        assertFalse(LocationRecordRules.shouldRestartOnBoot(enabled = true, hasBackgroundPermission = false))
        assertFalse(LocationRecordRules.shouldRestartOnBoot(enabled = false, hasBackgroundPermission = true))
        assertFalse(LocationRecordRules.shouldRestartOnBoot(enabled = false, hasBackgroundPermission = false))
    }

    // ── 상태 ──

    @Test
    fun `state is off when disabled whatever the permission`() {
        assertEquals("off", LocationRecordRules.stateOf(false, hasBackgroundPermission = true, locationOn = true))
        assertEquals("off", LocationRecordRules.stateOf(false, hasBackgroundPermission = false, locationOn = false))
    }

    @Test
    fun `state is running when enabled with permission and location on`() {
        assertEquals("running", LocationRecordRules.stateOf(true, hasBackgroundPermission = true, locationOn = true))
    }

    @Test
    fun `state is blocked when enabled without permission or location`() {
        assertEquals("blocked", LocationRecordRules.stateOf(true, hasBackgroundPermission = false, locationOn = true))
        assertEquals("blocked", LocationRecordRules.stateOf(true, hasBackgroundPermission = true, locationOn = false))
        assertEquals("blocked", LocationRecordRules.stateOf(true, hasBackgroundPermission = false, locationOn = false))
    }

    // ── 정지 감지 ──

    @Test
    fun `normal moving entering still pauses`() {
        assertEquals(
            Phase.STILL to Action.Pause,
            LocationRecordRules.onTransition("normal", Phase.MOVING, enteredStill = true, stillDetection = true),
        )
    }

    @Test
    fun `normal still leaving still resumes with a fix`() {
        assertEquals(
            Phase.MOVING to Action.ResumeAndFix,
            LocationRecordRules.onTransition("normal", Phase.STILL, enteredStill = false, stillDetection = true),
        )
    }

    @Test
    fun `duplicate transition into the same phase does nothing`() {
        assertEquals(
            Phase.STILL to Action.None,
            LocationRecordRules.onTransition("normal", Phase.STILL, enteredStill = true, stillDetection = true),
        )
        assertEquals(
            Phase.MOVING to Action.None,
            LocationRecordRules.onTransition("normal", Phase.MOVING, enteredStill = false, stillDetection = true),
        )
    }

    @Test
    fun `dense mode always stays moving`() {
        for (phase in Phase.values()) {
            for (entered in listOf(true, false)) {
                assertEquals(
                    Phase.MOVING to Action.None,
                    LocationRecordRules.onTransition("dense", phase, enteredStill = entered, stillDetection = true),
                )
            }
        }
    }

    @Test
    fun `without still detection always stays moving`() {
        for (phase in Phase.values()) {
            for (entered in listOf(true, false)) {
                assertEquals(
                    Phase.MOVING to Action.None,
                    LocationRecordRules.onTransition("normal", phase, enteredStill = entered, stillDetection = false),
                )
            }
        }
    }

    // ── 서비스 되살리기 · 새 인스턴스 ──

    @Test
    fun `revive only when enabled with permission and service dead`() {
        assertTrue(LocationRecordRules.shouldRevive(true, hasBackgroundPermission = true, serviceRunning = false))
        assertFalse(LocationRecordRules.shouldRevive(true, hasBackgroundPermission = true, serviceRunning = true))
        assertFalse(LocationRecordRules.shouldRevive(true, hasBackgroundPermission = false, serviceRunning = false))
        assertFalse(LocationRecordRules.shouldRevive(false, hasBackgroundPermission = true, serviceRunning = false))
    }

    @Test
    fun `new service instance starts moving even if still was saved`() {
        assertEquals(Phase.MOVING, LocationRecordRules.phaseOnServiceStart(newInstance = true, saved = Phase.STILL))
        assertEquals(Phase.MOVING, LocationRecordRules.phaseOnServiceStart(newInstance = true, saved = Phase.MOVING))
    }

    @Test
    fun `same instance keeps the saved phase`() {
        assertEquals(Phase.STILL, LocationRecordRules.phaseOnServiceStart(newInstance = false, saved = Phase.STILL))
    }

    // ── lastLocation 대체 ──

    @Test
    fun `fallback fix is used only within 5 minutes`() {
        val now = 1_000_000_000L
        assertTrue(LocationRecordRules.isFreshFallback(now, now))
        assertTrue(LocationRecordRules.isFreshFallback(now - 300_000L, now))
        assertFalse(LocationRecordRules.isFreshFallback(now - 300_001L, now))
        assertFalse(LocationRecordRules.isFreshFallback(now + 1L, now))
    }

    // ── 정지 중 감시(watchdog) ──

    @Test
    fun `watchdog request is passive every 15 minutes`() {
        val request = LocationRecordRules.watchdogRequest

        assertEquals(105, request.priority) // Priority.PRIORITY_PASSIVE
        assertEquals(900_000L, request.intervalMs)
        assertEquals(0f, request.minDistanceM)
        assertEquals(0L, request.maxDelayMs)
    }

    @Test
    fun `watchdog with unknown accuracy resumes only beyond 100m`() {
        assertFalse(LocationRecordRules.watchdogShouldResume(0f, null, null))
        assertFalse(LocationRecordRules.watchdogShouldResume(100f, null, null))
        assertTrue(LocationRecordRules.watchdogShouldResume(100.1f, null, null))
        assertTrue(LocationRecordRules.watchdogShouldResume(2_000f, null, null))
    }

    @Test
    fun `watchdog resumes on an accurate far fix`() {
        assertTrue(LocationRecordRules.watchdogShouldResume(300f, 20f, 15f))
    }

    @Test
    fun `watchdog ignores a far fix whose accuracy covers the distance`() {
        assertFalse(LocationRecordRules.watchdogShouldResume(300f, 500f, null))
        assertFalse(LocationRecordRules.watchdogShouldResume(300f, 150f, 50f))
        assertTrue(LocationRecordRules.watchdogShouldResume(300.1f, 150f, 50f))
    }

    @Test
    fun `still resume fix within 100m means still there`() {
        assertTrue(LocationRecordRules.stillResumeIsStillThere(0f))
        assertTrue(LocationRecordRules.stillResumeIsStillThere(100f))
        assertFalse(LocationRecordRules.stillResumeIsStillThere(100.1f))
        assertFalse(LocationRecordRules.stillResumeIsStillThere(2_000f))
    }

    @Test
    fun `still for more than 6 hours is too long`() {
        val since = 1_000_000_000L
        val sixHours = 6 * 60 * 60_000L
        assertFalse(LocationRecordRules.stillTooLong(since, since))
        assertFalse(LocationRecordRules.stillTooLong(since, since + sixHours))
        assertTrue(LocationRecordRules.stillTooLong(since, since + sixHours + 1))
    }

    @Test
    fun `still since in the future or unknown counts as too long`() {
        // 시계가 뒤로 갔거나 시작 시각을 모르면 갇히지 않게 다시 건다.
        val now = 1_000_000_000L
        assertTrue(LocationRecordRules.stillTooLong(now + 1, now))
        assertTrue(LocationRecordRules.stillTooLong(0L, now))
    }

    // ── 위치 요청 실패 재시도 ──

    @Test
    fun `failed location request retries after 60 seconds`() {
        assertEquals(60_000L, LocationRecordRules.UPDATES_RETRY_MS)
    }

    @Test
    fun `retry runs only for the same generation of a live service`() {
        assertTrue(LocationRecordRules.shouldRetryUpdates(gen = 3, currentGen = 3, destroyed = false))
        assertFalse(LocationRecordRules.shouldRetryUpdates(gen = 2, currentGen = 3, destroyed = false))
        assertFalse(LocationRecordRules.shouldRetryUpdates(gen = 3, currentGen = 3, destroyed = true))
    }
}
