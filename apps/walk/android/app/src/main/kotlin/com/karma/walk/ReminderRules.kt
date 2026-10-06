package com.karma.walk

/** 미리 알림 알림의 버튼. [action] 은 `skip`(Dart `skipOccurrence`) · `dismiss`(알림만 닫는다). */
internal data class ReminderAction(val action: String, val label: String)

/**
 * 미리 알림 저장 항목(`walk/reminders` 의 `schedule` 인자, `ChannelReminderScheduler.argumentsFor`).
 * [shown] 은 이미 띄웠다는 표시 — 알림이 닫혀도 [ringAtMillis] 까지 남아 `scheduled` 로 돌아간다.
 */
internal data class ReminderEntry(
    val id: Int,
    val packageId: Int,
    val kind: String,
    val atMillis: Long,
    val ringAtMillis: Long,
    val title: String,
    val body: String,
    val actions: List<ReminderAction>,
    val shown: Boolean = false,
)

/**
 * 미리 알림 저장 항목 모음(순수, 메모리). [ReminderStore] 가 SharedPreferences 와 오간다.
 *
 * 계약(`ChannelReminderScheduler` 문서 · 웨이브 3 스펙 §3.3): 띄운 항목은 알림이 닫혀도
 * ([울리기] · 밀어 지우기) [ReminderEntry.shown] 으로 울릴 시각까지 남는다 — 빠지면 Dart 가 아직
 * 안 띄운 것으로 보고 다시 걸어 같은 알림이 또 뜬다. 항목을 지우는 것은 [remove](Dart `cancel`)와
 * [pruneExpired](울릴 시각 경과)뿐이다.
 */
internal class ReminderBook(entries: Collection<ReminderEntry> = emptyList()) {
    private val entries = entries.associateByTo(sortedMapOf()) { it.id }

    fun all(): List<ReminderEntry> = entries.values.toList()

    fun get(id: Int): ReminderEntry? = entries[id]

    /** `scheduled`: 걸렸거나 떠 있는 것 — 울릴 시각 전. */
    fun scheduled(nowMillis: Long): List<ReminderEntry> =
        entries.values.filter { it.ringAtMillis > nowMillis }

    /** 같은 id 면 덮어쓰고 다시 안 띄운 것으로 둔다(새 회차 · 새 시각). */
    fun put(entry: ReminderEntry) {
        entries[entry.id] = entry.copy(shown = false)
    }

    fun markShown(id: Int) {
        entries[id]?.let { entries[id] = it.copy(shown = true) }
    }

    fun remove(id: Int) {
        entries.remove(id)
    }

    /**
     * 알림 버튼([action] 은 [ReminderAction.action])을 눌렀을 때.
     * - `dismiss`([울리기]): [ReminderRules.Action.CLOSE] — 알림만 닫는다. 항목은 [ReminderEntry.shown]
     *   으로 울릴 시각까지 남긴다(빠지면 다음 sync 가 다시 걸어 같은 알림이 또 뜬다).
     * - `skip`: [ReminderRules.Action.SKIP] — Dart `skipOccurrence`. 항목은 Dart sync 가 `cancel` 로 지운다.
     * - 항목이 없거나(취소됨) 울릴 시각이 지났거나 모르는 버튼이면 [ReminderRules.Action.STALE] — Dart 에
     *   보내지 않는다. 울린 뒤 스누즈된 회차를 옛 알림이 지우면 안 된다. 지난 항목은 지운다.
     */
    fun onAction(id: Int, action: String, nowMillis: Long): ReminderRules.Action {
        val entry = entries[id] ?: return ReminderRules.Action.STALE
        if (entry.ringAtMillis <= nowMillis) {
            entries.remove(id)
            return ReminderRules.Action.STALE
        }
        return when (action) {
            "dismiss" -> {
                markShown(id)
                ReminderRules.Action.CLOSE
            }
            "skip" -> ReminderRules.Action.SKIP
            else -> ReminderRules.Action.STALE
        }
    }

    /** 울릴 시각이 지난 항목을 지우고 그 id 를 돌려준다. */
    fun pruneExpired(nowMillis: Long): List<Int> {
        val expired = entries.values.filter { it.ringAtMillis <= nowMillis }.map { it.id }
        expired.forEach(entries::remove)
        return expired
    }
}

/** 미리 알림을 언제 걸고 띄울지(순수). */
internal object ReminderRules {
    /** 재부팅 동안 띄울 시각을 놓쳤어도 울릴 시각까지 이보다 많이 남았으면 바로 띄운다. */
    const val BOOT_SHOW_MIN_LEFT_MS = 60_000L

    enum class Schedule { ARM, SHOW_NOW, DROP }

    enum class Fire { SHOW, DROP, IGNORE }

    enum class Boot { ARM, SHOW_NOW, MARK_SHOWN, KEEP, DROP }

    /** 알림 버튼([ReminderBook.onAction]). */
    enum class Action { CLOSE, SKIP, STALE }

    /**
     * 띄운 알림이 저절로 닫힐 때까지(`Notification.Builder.setTimeoutAfter`) — 울릴 시각. Dart sync 가
     * 돌지 않아도(앱이 꺼진 채 울리고 스누즈 · 끄기) 지난 회차의 알림이 남지 않는다.
     */
    fun timeoutAfter(entry: ReminderEntry, nowMillis: Long): Long =
        maxOf(1L, entry.ringAtMillis - nowMillis)

    /** `schedule` 받았을 때. 띄울 시각이 지났으면 바로 띄운다(공휴일 알림의 `at = now`). */
    fun onSchedule(entry: ReminderEntry, nowMillis: Long): Schedule = when {
        entry.ringAtMillis <= nowMillis -> Schedule.DROP
        entry.atMillis <= nowMillis -> Schedule.SHOW_NOW
        else -> Schedule.ARM
    }

    /** AlarmManager 가 띄울 시각에 깨웠을 때. 항목이 없으면(취소됨) 아무것도 안 한다. */
    fun onFire(entry: ReminderEntry?, nowMillis: Long): Fire = when {
        entry == null -> Fire.IGNORE
        entry.ringAtMillis <= nowMillis -> Fire.DROP
        else -> Fire.SHOW
    }

    /**
     * 재부팅 · 앱 업데이트 뒤. 띄운 항목은 다시 띄우지 않고 남긴다(알림은 재부팅으로 사라졌다).
     * 놓친 항목은 울릴 시각까지 1분보다 많이 남았을 때만 바로 띄우고, 아니면 띄운 것으로 둔다
     * (지우면 Dart 가 다시 걸어 울리기 직전에 뜬다).
     */
    fun onBoot(entry: ReminderEntry, nowMillis: Long): Boot = when {
        entry.ringAtMillis <= nowMillis -> Boot.DROP
        entry.shown -> Boot.KEEP
        entry.atMillis > nowMillis -> Boot.ARM
        entry.ringAtMillis - nowMillis > BOOT_SHOW_MIN_LEFT_MS -> Boot.SHOW_NOW
        else -> Boot.MARK_SHOWN
    }
}
