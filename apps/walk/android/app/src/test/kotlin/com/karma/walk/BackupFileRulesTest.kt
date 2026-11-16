package com.karma.walk

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

class BackupFileRulesTest {
    @Test
    fun `빈 입력은 0 바이트를 복사한다`() {
        val out = ByteArrayOutputStream()
        assertEquals(0L, BackupFileRules.copyStream(ByteArrayInputStream(ByteArray(0)), out))
        assertEquals(0, out.size())
    }

    @Test
    fun `버퍼보다 큰 입력도 바이트 그대로 복사하고 개수를 돌려준다`() {
        val data = ByteArray(3 * BackupFileRules.BUFFER_BYTES + 17) { (it * 31).toByte() }
        val out = ByteArrayOutputStream()
        assertEquals(data.size.toLong(), BackupFileRules.copyStream(ByteArrayInputStream(data), out))
        assertTrue(data.contentEquals(out.toByteArray()))
    }
}
