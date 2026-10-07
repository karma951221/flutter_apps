package com.karma.walk

/**
 * 헤드리스 엔진 일이 도는 동안 앱(메인 엔진)을 기다리게 하는 규칙(순수).
 *
 * 미리 알림 [이번만 끄기]를 헤드리스 엔진이 처리하는 중에 앱을 열면, 메인 엔진의 첫 sync 가 헤드리스가
 * `skippedAt` 을 쓰기 직전 저장소를 읽고 지운 회차를 다시 걸 수 있다. 그래서 메인 엔진은 sync 앞에
 * `walk/background` 의 `awaitIdle` 을 부르고, [BackgroundDispatcher] 는 헤드리스 일이 끝날 때까지
 * 답을 미룬다.
 *
 * - [await]: 헤드리스 일이 없으면 true(바로 답한다), 있으면 대기자로 남기고 false.
 * - [started]: 새 실행이 시작됐다. 헤드리스면 계속 기다리게 하고, 메인 엔진이면 대기자를 풀어 준다
 *   (메인 엔진 일은 같은 isolate 의 직렬 줄에 서므로 기다릴 필요가 없다).
 * - [stopped]: 도는 일이 없다. 대기자를 풀어 준다.
 *
 * 풀어 준 대기자는 한 번만 돌려준다. 스레드 안전하지 않다 — 메인 스레드에서만 부른다.
 */
internal class HeadlessIdleGate<W> {
    var busy = false
        private set

    private val waiters = mutableListOf<W>()

    fun await(waiter: W): Boolean {
        if (!busy) return true
        waiters += waiter
        return false
    }

    fun started(headless: Boolean): List<W> {
        if (headless) {
            busy = true
            return emptyList()
        }
        return stopped()
    }

    fun stopped(): List<W> {
        busy = false
        val released = waiters.toList()
        waiters.clear()
        return released
    }
}
