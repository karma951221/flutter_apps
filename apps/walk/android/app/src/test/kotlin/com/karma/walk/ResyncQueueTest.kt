package com.karma.walk

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ResyncQueueTest {
    private val queue = ResyncQueue<String>()

    @Test
    fun `first request starts a run`() {
        assertTrue(queue.request("a"))
    }

    @Test
    fun `run without new requests ends and serves its waiters`() {
        queue.request("a")

        val end = queue.finish()

        assertEquals(listOf("a"), end.served)
        assertFalse(end.again)
    }

    @Test
    fun `request while running does not start but runs once more after the run ends`() {
        queue.request("a")

        assertFalse(queue.request("b"))
        val first = queue.finish()

        assertEquals(listOf("a"), first.served)
        assertTrue(first.again)
        val second = queue.finish()
        assertEquals(listOf("b"), second.served)
        assertFalse(second.again)
    }

    @Test
    fun `many requests while running collapse into one more run`() {
        queue.request("a")
        assertFalse(queue.request("b"))
        assertFalse(queue.request("c"))
        assertFalse(queue.request("d"))

        assertTrue(queue.finish().again)
        val second = queue.finish()

        assertEquals(listOf("b", "c", "d"), second.served)
        assertFalse(second.again)
    }

    @Test
    fun `request during the extra run queues yet another run`() {
        queue.request("a")
        queue.request("b")
        queue.finish()

        assertFalse(queue.request("c"))

        val second = queue.finish()
        assertEquals(listOf("b"), second.served)
        assertTrue(second.again)
        assertEquals(listOf("c"), queue.finish().served)
    }

    @Test
    fun `after the queue goes idle the next request starts a new run`() {
        queue.request("a")
        queue.finish()

        assertTrue(queue.request("b"))
    }

    @Test
    fun `cancelled waiter is not served but its request still runs once more`() {
        queue.request("a")
        queue.request("b")

        queue.cancel("a")
        queue.cancel("b")

        val first = queue.finish()
        assertEquals(emptyList<String>(), first.served)
        assertTrue(first.again)
        val second = queue.finish()
        assertEquals(emptyList<String>(), second.served)
        assertFalse(second.again)
    }

    @Test
    fun `waiting lists the waiters of the run in progress`() {
        queue.request("a")
        queue.request("b")
        queue.request("c")
        queue.cancel("c")
        assertEquals(listOf("a"), queue.waiting())

        queue.finish()

        assertEquals(listOf("b"), queue.waiting())
        queue.finish()
        assertEquals(emptyList<String>(), queue.waiting())
    }
}
