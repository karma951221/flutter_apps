package com.karma.walk

import java.io.File
import java.io.IOException
import java.nio.file.Files
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test

class VerifiedReplaceTest {
    private lateinit var folder: File
    private lateinit var target: File

    @Before
    fun setUp() {
        folder = Files.createTempDirectory("alarm_sounds").toFile()
        target = File(folder, "abc.ogg")
    }

    private fun leftovers() = folder.listFiles()!!.map { it.name }.sorted()

    @Test
    fun `new file is written and verified, then appears at target`() {
        val verified = mutableListOf<File>()
        replaceVerified(target, write = { it.writeText("new") }, verify = { verified += it })

        assertEquals("new", target.readText())
        assertEquals(1, verified.size)
        assertTrue("verify must see the temp file, not the target", verified[0] != target)
        assertEquals(listOf("abc.ogg"), leftovers())
    }

    @Test
    fun `success overwrites an existing copy`() {
        target.writeText("old")
        replaceVerified(target, write = { it.writeText("new") }, verify = {})
        assertEquals("new", target.readText())
        assertEquals(listOf("abc.ogg"), leftovers())
    }

    @Test
    fun `write failure keeps the existing copy and removes the temp file`() {
        target.writeText("old")
        try {
            replaceVerified(
                target,
                write = {
                    it.writeText("par")
                    throw IOException("disk full")
                },
                verify = {},
            )
            fail("should throw")
        } catch (e: IOException) {
            assertEquals("disk full", e.message)
        }
        assertEquals("old", target.readText())
        assertEquals(listOf("abc.ogg"), leftovers())
    }

    @Test
    fun `verify failure keeps the existing copy and removes the temp file`() {
        target.writeText("old")
        try {
            replaceVerified(
                target,
                write = { it.writeText("broken") },
                verify = { throw IllegalStateException("prepare failed") },
            )
            fail("should throw")
        } catch (e: IllegalStateException) {
            assertEquals("prepare failed", e.message)
        }
        assertEquals("old", target.readText())
        assertEquals(listOf("abc.ogg"), leftovers())
    }

    @Test
    fun `failure without an existing copy leaves nothing behind`() {
        try {
            replaceVerified(target, write = { throw IOException("cannot open") }, verify = {})
            fail("should throw")
        } catch (_: IOException) {
        }
        assertFalse(target.exists())
        assertEquals(emptyList<String>(), leftovers())
    }

    @Test
    fun `temp file keeps the extension last so MediaPlayer can sniff it`() {
        var seen: File? = null
        replaceVerified(target, write = { seen = it; it.writeText("x") }, verify = {})
        assertEquals("ogg", seen!!.extension)
    }
}
