package com.karma.walk

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HeadlessIdleGateTest {
    private val gate = HeadlessIdleGate<String>()

    @Test
    fun `nothing running answers right away`() {
        assertTrue(gate.await("app"))
        assertFalse(gate.busy)
    }

    @Test
    fun `while a headless run is going the app waits until it stops`() {
        assertEquals(emptyList<String>(), gate.started(headless = true))
        assertTrue(gate.busy)

        assertFalse(gate.await("app"))
        assertFalse(gate.await("app2"))

        assertEquals(listOf("app", "app2"), gate.stopped())
        assertFalse(gate.busy)
        assertTrue(gate.await("later"))
    }

    @Test
    fun `next run on the main engine releases the waiters`() {
        gate.started(headless = true)
        gate.await("app")

        assertEquals(listOf("app"), gate.started(headless = false))
        assertFalse(gate.busy)
        assertTrue(gate.await("later"))
    }

    @Test
    fun `next headless run keeps the waiters waiting`() {
        gate.started(headless = true)
        gate.await("app")

        assertEquals(emptyList<String>(), gate.started(headless = true))
        assertTrue(gate.busy)
        assertEquals(listOf("app"), gate.stopped())
    }

    @Test
    fun `waiters are released once`() {
        gate.started(headless = true)
        gate.await("app")

        assertEquals(listOf("app"), gate.stopped())
        assertEquals(emptyList<String>(), gate.stopped())
        assertEquals(emptyList<String>(), gate.started(headless = false))
    }
}
