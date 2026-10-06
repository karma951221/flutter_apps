package com.karma.walk

import java.io.File
import java.io.IOException

/**
 * [target] 을 검증된 새 내용으로 바꾼다. 같은 폴더의 임시 파일에 [write] 하고 [verify] 한 뒤
 * rename 으로 한 번에 바꾼다. 어느 단계든 실패하면 임시 파일만 지우고 던진다 — 이미 있던
 * [target](다른 알람이 쓰는 복사본일 수 있다)은 그대로 남고, 울리는 중인 알람이 반쯤 쓴 파일을
 * 읽는 일도 없다. 임시 파일은 확장자를 끝에 둔다(`<이름>.tmp.<확장자>`).
 */
internal fun replaceVerified(target: File, write: (File) -> Unit, verify: (File) -> Unit) {
    val name = target.nameWithoutExtension
    val extension = target.extension
    val temp = File(target.parentFile, if (extension.isEmpty()) "$name.tmp" else "$name.tmp.$extension")
    try {
        write(temp)
        verify(temp)
        if (!temp.renameTo(target)) throw IOException("cannot replace $target")
    } catch (e: Exception) {
        temp.delete()
        throw e
    }
}
