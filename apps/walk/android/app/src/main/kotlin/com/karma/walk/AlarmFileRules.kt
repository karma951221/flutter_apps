package com.karma.walk

import java.io.IOException
import java.io.InputStream
import java.io.OutputStream

/** 사용자가 고른 오디오 파일을 알람음으로 받을 때의 순수 규칙(크기 상한 · 표시 이름). */
object AlarmFileRules {
    /** 복사본이 앱 저장소를 너무 차지하지 않게 하는 상한. 알람음으로는 넉넉하다. */
    const val MAX_BYTES = 30L * 1024 * 1024

    /** 크기를 모르면(제공자가 안 알려 줌) 여기선 받고, 복사 중 상한이 막는다. */
    fun isTooLarge(size: Long?): Boolean = size != null && size > MAX_BYTES

    /** 마지막 `.` 뒤 확장자를 떼고 공백을 다듬는다. 남는 것이 없으면 [fallback]. */
    fun titleOf(displayName: String?, fallback: String): String {
        val name = displayName?.trim().orEmpty()
        val dot = name.lastIndexOf('.')
        val stem = (if (dot >= 0) name.substring(0, dot) else name).trim()
        return stem.ifEmpty { fallback }
    }

    /**
     * [input] 을 [output] 에 복사하되 [maxBytes] 를 넘으면 [AlarmFileTooLargeException] 으로 멈춘다.
     * 제공자가 크기를 안 알려 주거나 틀리게 알려 줘도 상한을 지킨다. 복사한 바이트 수를 돌려준다.
     */
    fun copyBounded(input: InputStream, output: OutputStream, maxBytes: Long): Long {
        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
        var total = 0L
        while (true) {
            val read = input.read(buffer)
            if (read < 0) return total
            total += read
            if (total > maxBytes) throw AlarmFileTooLargeException()
            output.write(buffer, 0, read)
        }
    }
}

/** 고른 파일이 [AlarmFileRules.MAX_BYTES] 를 넘는다. 채널 오류 코드 `too_large`. */
class AlarmFileTooLargeException : IOException("file is larger than ${AlarmFileRules.MAX_BYTES} bytes")

/**
 * 결과를 기다리는 호출 하나를 담는 칸. 새 것이 오면 남아 있던 옛 것을 돌려주고 바꾼다 — 옛 결과가
 * 사라졌을 때(엔진은 살아 있는데 액티비티가 다시 만들어짐 등) 칸이 영영 막히지 않게 한다.
 */
class PendingSlot<T> {
    private var value: T? = null

    /** [next] 로 바꾸고, 그 전에 있던 것을 돌려준다(없으면 null). */
    fun replace(next: T): T? = value.also { value = next }

    /** 꺼내고 비운다. */
    fun take(): T? = value.also { value = null }

    fun clear() {
        value = null
    }
}
