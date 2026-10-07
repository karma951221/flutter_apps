package com.karma.walk

/**
 * `READ_CALENDAR` 상태를 Dart `PermissionStatus` 이름으로 고르는 순수 규칙. [CalendarPermissionChannel] 이
 * 시스템 값을 모아 부른다.
 *
 * 안드로이드는 "다시 묻지 않음"을 직접 알려 주지 않는다. 한 번 진짜로 거부하면 `shouldShowRequestPermissionRationale`
 * 이 true 가 되고, 그 뒤 다시 거부하면(또는 설정에서 막으면) false 로 돌아간다 — 그래서 rationale 을 본 적이
 * 있는데 지금 false 면 시스템이 더 이상 대화상자를 띄우지 않는 상태(영구 거부)로 본다. 대화상자를 바깥 탭으로
 * 닫은 경우는 rationale 이 그대로라 영구 거부로 잘못 보지 않는다.
 */
object CalendarPermissionRules {
    const val GRANTED = "granted"
    const val DENIED = "denied"
    const val PERMANENTLY_DENIED = "permanentlyDenied"

    fun status(granted: Boolean, showRationale: Boolean, rationaleSeen: Boolean): String =
        when {
            granted -> GRANTED
            showRationale -> DENIED
            rationaleSeen -> PERMANENTLY_DENIED
            else -> DENIED
        }

    /** rationale 을 한 번이라도 봤는지 — 저장해 두고 다음 판정에 쓴다. */
    fun seen(previous: Boolean, showRationale: Boolean): Boolean = previous || showRationale
}
