package com.karma.walk

/**
 * "설정 열기"가 차례로 시도할 Health Connect 화면. [MainActivity] 가 처음 열리는 것을 쓴다.
 *
 * 안드로이드 14 부터 Health Connect 는 프레임워크에 들어가 `androidx.health.ACTION_HEALTH_CONNECT_SETTINGS`
 * 를 받는 화면이 없다(에뮬레이터 API 37 에서 확인). 그래서 이 앱의 권한 화면을 먼저, 안 되면 Health Connect
 * 첫 화면을 연다. 13 이하는 Health Connect 앱의 설정 화면이다.
 */
object HealthSettingsRules {
    /** [packageName] 이 있으면 `Intent.EXTRA_PACKAGE_NAME` 으로 넘긴다. */
    data class Target(val action: String, val packageName: String?)

    private const val UPSIDE_DOWN_CAKE = 34

    fun targets(sdkInt: Int, packageName: String): List<Target> =
        if (sdkInt >= UPSIDE_DOWN_CAKE) {
            listOf(
                Target("android.health.connect.action.MANAGE_HEALTH_PERMISSIONS", packageName),
                Target("android.health.connect.action.HEALTH_HOME_SETTINGS", null),
            )
        } else {
            listOf(Target("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS", null))
        }
}
