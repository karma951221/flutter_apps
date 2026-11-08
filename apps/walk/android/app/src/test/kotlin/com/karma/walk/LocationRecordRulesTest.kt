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
}
