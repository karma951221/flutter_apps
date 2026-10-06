package com.gdelataillade.alarm.alarm

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class EngineRegistryTest {
    private val registry = EngineRegistry<String, String>()

    @Test
    fun `empty registry has no current value`() {
        assertNull(registry.current)
    }

    @Test
    fun `attached engine becomes current`() {
        registry.attach("main", "mainApi")

        assertEquals("mainApi", registry.current)
    }

    @Test
    fun `latest attached engine wins`() {
        registry.attach("headless", "headlessApi")
        registry.attach("main", "mainApi")

        assertEquals("mainApi", registry.current)
    }

    @Test
    fun `detaching an earlier engine keeps the later engine current`() {
        registry.attach("headless", "headlessApi")
        registry.attach("main", "mainApi")

        registry.detach("headless")

        assertEquals("mainApi", registry.current)
    }

    @Test
    fun `detaching the current engine falls back to the one still attached`() {
        registry.attach("main", "mainApi")
        registry.attach("headless", "headlessApi")

        registry.detach("headless")

        assertEquals("mainApi", registry.current)
    }

    @Test
    fun `detaching the last engine clears current`() {
        registry.attach("main", "mainApi")

        registry.detach("main")

        assertNull(registry.current)
    }

    @Test
    fun `reattaching the same engine replaces its value without duplicating`() {
        registry.attach("main", "old")
        registry.attach("main", "new")

        registry.detach("main")

        assertNull(registry.current)
    }

    @Test
    fun `detaching an unknown engine changes nothing`() {
        registry.attach("main", "mainApi")

        registry.detach("other")

        assertEquals("mainApi", registry.current)
    }
}
