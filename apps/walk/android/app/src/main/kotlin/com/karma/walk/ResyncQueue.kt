package com.karma.walk

/**
 * 알람 resync 직렬화 규칙(순수). 한 번에 하나만 돌고, 도는 중에 들어온 요청은 몇 번이 오든
 * 끝난 뒤 **한 번 더** 돈다 — 도는 중에 바뀐 것(시간대 · 알람)을 놓치지 않으면서 쌓이지 않는다.
 *
 * [W] 는 결과를 기다리는 쪽(대기자)이다. 실행이 끝나면 그 실행을 시작할 때 묶인 대기자에게
 * 알리고([Finish.served]), 도는 중에 들어온 대기자는 다음 실행에 묶인다. [cancel] 로 빠진
 * 대기자는 알림을 받지 않지만, 그 요청이 부른 "한 번 더" 는 그대로 남는다.
 *
 * 스레드 안전하지 않다. [AlarmResync] 가 메인 스레드에서만 부른다.
 */
internal class ResyncQueue<W> {
    class Finish<W>(val served: List<W>, val again: Boolean)

    private var running = false
    private var again = false
    private val current = mutableListOf<W>()
    private val next = mutableListOf<W>()

    /** 요청을 넣는다. 지금 실행을 시작해야 하면 true(쉬고 있었다). */
    fun request(waiter: W): Boolean {
        if (!running) {
            running = true
            current += waiter
            return true
        }
        again = true
        next += waiter
        return false
    }

    /** 대기자를 뺀다(시간 초과 · 취소). 요청 자체는 취소하지 않는다. */
    fun cancel(waiter: W) {
        current.remove(waiter)
        next.remove(waiter)
    }

    /** 지금 실행을 기다리는 대기자(빠진 대기자 제외). */
    fun waiting(): List<W> = current.toList()

    /** 지금 실행이 끝났다. [Finish.again] 이면 부르는 쪽이 곧바로 한 번 더 실행한다. */
    fun finish(): Finish<W> {
        check(running) { "finish without a run" }
        val served = current.toList()
        current.clear()
        if (again) {
            again = false
            current += next
            next.clear()
        } else {
            running = false
        }
        return Finish(served, running)
    }
}
