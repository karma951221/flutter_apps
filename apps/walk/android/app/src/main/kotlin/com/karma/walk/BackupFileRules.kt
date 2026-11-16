package com.karma.walk

import java.io.InputStream
import java.io.OutputStream

/** 백업 파일 저장 · 열기의 순수 규칙. */
object BackupFileRules {
    /** 한 번에 옮기는 크기. 백업 파일은 수백 MB 가 될 수 있어 전체를 메모리에 올리지 않는다. */
    const val BUFFER_BYTES = 64 * 1024

    /** [input] 을 [output] 에 [BUFFER_BYTES] 씩 옮기고 복사한 바이트 수를 돌려준다. 닫지는 않는다. */
    fun copyStream(input: InputStream, output: OutputStream): Long {
        val buffer = ByteArray(BUFFER_BYTES)
        var total = 0L
        while (true) {
            val read = input.read(buffer)
            if (read < 0) return total
            output.write(buffer, 0, read)
            total += read
        }
    }
}
