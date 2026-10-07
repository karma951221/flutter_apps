package com.karma.walk

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CalendarPermissionRulesTest {
    @Test
    fun `granted wins over everything`() {
        assertEquals("granted", CalendarPermissionRules.status(granted = true, showRationale = false, rationaleSeen = true))
        assertEquals("granted", CalendarPermissionRules.status(granted = true, showRationale = true, rationaleSeen = false))
    }

    @Test
    fun `never denied for real is plain denied so the dialog can show`() {
        assertEquals("denied", CalendarPermissionRules.status(granted = false, showRationale = false, rationaleSeen = false))
    }

    @Test
    fun `denied once with rationale is still askable`() {
        assertEquals("denied", CalendarPermissionRules.status(granted = false, showRationale = true, rationaleSeen = true))
        assertEquals("denied", CalendarPermissionRules.status(granted = false, showRationale = true, rationaleSeen = false))
    }

    @Test
    fun `rationale gone after it was seen means the system stopped asking`() {
        assertEquals(
            "permanentlyDenied",
            CalendarPermissionRules.status(granted = false, showRationale = false, rationaleSeen = true),
        )
    }

    @Test
    fun `seen remembers rationale once shown`() {
        assertFalse(CalendarPermissionRules.seen(previous = false, showRationale = false))
        assertTrue(CalendarPermissionRules.seen(previous = false, showRationale = true))
        assertTrue(CalendarPermissionRules.seen(previous = true, showRationale = false))
    }
}
