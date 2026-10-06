package com.gdelataillade.alarm.alarm

/**
 * Fork: 엔진(키)마다 붙은 값을 기억하고, 아직 붙어 있는 것 중 가장 나중에 붙은 엔진의 값을 [current] 로 준다.
 *
 * 원본은 `AlarmPlugin.alarmTriggerApi` 하나를 attach 때 덮어쓰고 detach 때 무조건 비웠다. 그래서 앱 엔진이
 * 헤드리스 엔진보다 나중에 붙은 뒤 헤드리스 엔진이 내려가면 앱 엔진의 API 까지 사라졌다. 키는 동일성(`===`)으로
 * 비교한다(엔진의 `BinaryMessenger`).
 */
internal class EngineRegistry<K : Any, V : Any> {
    private val entries = mutableListOf<Pair<K, V>>()

    val current: V?
        get() = entries.lastOrNull()?.second

    fun attach(key: K, value: V) {
        entries.removeAll { it.first === key }
        entries.add(key to value)
    }

    fun detach(key: K) {
        entries.removeAll { it.first === key }
    }
}
