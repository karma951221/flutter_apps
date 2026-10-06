package com.karma.walk

/**
 * 백그라운드 일 직렬화 규칙(순수). 일([K] — resync · 미리 알림 액션)은 한 번에 하나만 돌고
 * (헤드리스 엔진이 둘 뜨지 않게), 기다리는 일은 들어온 순서대로 돈다.
 *
 * - 기다리는 일과 같은 일이 또 오면 줄을 하나 더 세우지 않고 그 일의 대기자로 묶인다.
 * - 도는 중인 일과 같은 일이 오면 끝난 뒤 **한 번 더** 돈다(웨이브 1 resync 규칙 — 도는 중에
 *   바뀐 것을 놓치지 않으면서 쌓이지 않는다). 그 사이 기다리던 다른 일이 먼저 돈다.
 *
 * [W] 는 결과를 기다리는 쪽(대기자)이다. 실행이 끝나면 그 실행에 묶인 대기자에게 알린다
 * ([Finish.served]). [cancel] 로 빠진 대기자는 알림을 받지 않지만, 그 요청이 세운 일은 그대로 돈다.
 *
 * 스레드 안전하지 않다. [BackgroundDispatcher] 가 메인 스레드에서만 부른다.
 */
internal class BackgroundQueue<K : Any, W> {
    /** [next] 가 null 이 아니면 부르는 쪽이 곧바로 그 일을 실행한다. */
    class Finish<K, W>(val served: List<W>, val next: K?)

    private var running: K? = null
    private val current = mutableListOf<W>()
    private val pending = LinkedHashMap<K, MutableList<W>>()

    /** 요청을 넣는다. 지금 [job] 실행을 시작해야 하면 true(쉬고 있었다). */
    fun request(job: K, waiter: W): Boolean {
        if (running == null) {
            running = job
            current += waiter
            return true
        }
        pending.getOrPut(job) { mutableListOf() } += waiter
        return false
    }

    /** 대기자를 뺀다(시간 초과 · 취소). 요청 자체는 취소하지 않는다. */
    fun cancel(waiter: W) {
        current.remove(waiter)
        for (waiters in pending.values) waiters.remove(waiter)
    }

    /** 지금 도는 일. 쉬고 있으면 null. */
    fun running(): K? = running

    /** 지금 실행을 기다리는 대기자(빠진 대기자 제외). */
    fun waiting(): List<W> = current.toList()

    /** 지금 실행이 끝났다. */
    fun finish(): Finish<K, W> {
        checkNotNull(running) { "finish without a run" }
        val served = current.toList()
        current.clear()
        val next = pending.entries.firstOrNull()
        if (next == null) {
            running = null
        } else {
            pending.remove(next.key)
            running = next.key
            current += next.value
        }
        return Finish(served, running)
    }
}
