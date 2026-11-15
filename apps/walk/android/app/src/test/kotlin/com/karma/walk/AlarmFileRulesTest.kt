package com.karma.walk

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

class AlarmFileRulesTest {
    private val fallback = "내 파일"

    @Test
    fun `30MB 까지는 쓸 수 있다`() {
        assertFalse(AlarmFileRules.isTooLarge(30L * 1024 * 1024))
        assertEquals(30L * 1024 * 1024, AlarmFileRules.MAX_BYTES)
    }

    @Test
    fun `30MB 를 넘으면 너무 크다`() {
        assertTrue(AlarmFileRules.isTooLarge(30L * 1024 * 1024 + 1))
    }

    @Test
    fun `크기를 모르면 일단 받는다 — 복사 중 상한이 막는다`() {
        assertFalse(AlarmFileRules.isTooLarge(null))
    }

    @Test
    fun `표시 이름은 확장자를 뗀다`() {
        assertEquals("wake up", AlarmFileRules.titleOf("wake up.mp3", fallback))
    }

    @Test
    fun `확장자만 있으면 기본 이름`() {
        assertEquals(fallback, AlarmFileRules.titleOf(".mp3", fallback))
    }

    @Test
    fun `이름이 없으면 기본 이름`() {
        assertEquals(fallback, AlarmFileRules.titleOf(null, fallback))
    }

    @Test
    fun `마지막 점 뒤만 떼고 공백을 다듬는다`() {
        assertEquals("a.b", AlarmFileRules.titleOf("  a.b.ogg ", fallback))
    }

    @Test
    fun `상한 이하는 그대로 복사한다`() {
        val data = ByteArray(10_000) { it.toByte() }
        val out = ByteArrayOutputStream()
        assertEquals(10_000L, AlarmFileRules.copyBounded(ByteArrayInputStream(data), out, maxBytes = 10_000))
        assertTrue(data.contentEquals(out.toByteArray()))
    }

    @Test(expected = AlarmFileTooLargeException::class)
    fun `상한을 넘으면 복사 중에 멈춘다`() {
        AlarmFileRules.copyBounded(ByteArrayInputStream(ByteArray(10_001)), ByteArrayOutputStream(), maxBytes = 10_000)
    }

    @Test
    fun `새 선택이 오면 남아 있던 옛 선택을 돌려주고 새 것으로 바꾼다`() {
        val slot = PendingSlot<String>()
        assertEquals(null, slot.replace("first"))
        assertEquals("first", slot.replace("second"))
        assertEquals("second", slot.take())
        assertEquals(null, slot.take())
    }

    @Test
    fun `비우면 늦게 온 결과는 받을 것이 없다`() {
        val slot = PendingSlot<String>()
        slot.replace("first")
        slot.clear()
        assertEquals(null, slot.take())
    }
}
