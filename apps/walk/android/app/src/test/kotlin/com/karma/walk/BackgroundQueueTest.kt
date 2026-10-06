package com.karma.walk

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class BackgroundQueueTest {
    private val queue = BackgroundQueue<String, String>()

    // ── 한 가지 일(resync) — 웨이브 1 ResyncQueue 와 같은 규칙 ──

    @Test
    fun `first request starts a run`() {
        assertTrue(queue.request("resync", "a"))
        assertEquals("resync", queue.running())
    }

    @Test
    fun `run without new requests ends and serves its waiters`() {
        queue.request("resync", "a")

        val end = queue.finish()

        assertEquals(listOf("a"), end.served)
        assertNull(end.next)
        assertNull(queue.running())
    }

    @Test
    fun `request while running does not start but runs once more after the run ends`() {
        queue.request("resync", "a")

        assertFalse(queue.request("resync", "b"))
        val first = queue.finish()

        assertEquals(listOf("a"), first.served)
        assertEquals("resync", first.next)
        val second = queue.finish()
        assertEquals(listOf("b"), second.served)
        assertNull(second.next)
    }

    @Test
    fun `many requests while running collapse into one more run`() {
        queue.request("resync", "a")
        assertFalse(queue.request("resync", "b"))
        assertFalse(queue.request("resync", "c"))
        assertFalse(queue.request("resync", "d"))

        assertEquals("resync", queue.finish().next)
        val second = queue.finish()

        assertEquals(listOf("b", "c", "d"), second.served)
        assertNull(second.next)
    }

    @Test
    fun `request during the extra run queues yet another run`() {
        queue.request("resync", "a")
        queue.request("resync", "b")
        queue.finish()

        assertFalse(queue.request("resync", "c"))

        val second = queue.finish()
        assertEquals(listOf("b"), second.served)
        assertEquals("resync", second.next)
        assertEquals(listOf("c"), queue.finish().served)
    }

    @Test
    fun `after the queue goes idle the next request starts a new run`() {
        queue.request("resync", "a")
        queue.finish()

        assertTrue(queue.request("resync", "b"))
    }

    @Test
    fun `cancelled waiter is not served but its request still runs once more`() {
        queue.request("resync", "a")
        queue.request("resync", "b")

        queue.cancel("a")
        queue.cancel("b")

        val first = queue.finish()
        assertEquals(emptyList<String>(), first.served)
        assertEquals("resync", first.next)
        val second = queue.finish()
        assertEquals(emptyList<String>(), second.served)
        assertNull(second.next)
    }

    @Test
    fun `waiting lists the waiters of the run in progress`() {
        queue.request("resync", "a")
        queue.request("resync", "b")
        queue.request("resync", "c")
        queue.cancel("c")
        assertEquals(listOf("a"), queue.waiting())

        queue.finish()

        assertEquals(listOf("b"), queue.waiting())
        queue.finish()
        assertEquals(emptyList<String>(), queue.waiting())
    }

    // ── 여러 가지 일(resync · 미리 알림 액션) — 한 번에 하나, 들어온 순서대로 ──

    @Test
    fun `a different job while running waits and runs next in arrival order`() {
        queue.request("resync", "a")

        assertFalse(queue.request("skip:1203", "b"))
        assertFalse(queue.request("skip:1501", "c"))

        assertEquals("skip:1203", queue.finish().next)
        assertEquals(listOf("b"), queue.waiting())
        assertEquals("skip:1501", queue.finish().next)
        assertEquals(listOf("c"), queue.finish().served)
        assertNull(queue.running())
    }

    @Test
    fun `the same pending job is not queued twice and serves all its waiters`() {
        queue.request("resync", "a")
        queue.request("skip:1203", "b")
        queue.request("skip:1203", "c")

        assertEquals("skip:1203", queue.finish().next)
        val second = queue.finish()

        assertEquals(listOf("b", "c"), second.served)
        assertNull(second.next)
    }

    @Test
    fun `running job requested again runs once more after jobs already waiting`() {
        queue.request("resync", "a")
        queue.request("skip:1203", "b")
        queue.request("resync", "c")

        assertEquals("skip:1203", queue.finish().next)
        assertEquals("resync", queue.finish().next)
        assertEquals(listOf("c"), queue.finish().served)
    }
}
