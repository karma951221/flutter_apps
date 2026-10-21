package com.karma.walk

import org.junit.Assert.assertEquals
import org.junit.Test

class HealthSettingsRulesTest {
    @Test
    fun `android 14 and later opens the framework Health Connect home that lists this app`() {
        assertEquals(
            listOf(HealthSettingsRules.Target("android.health.connect.action.HEALTH_HOME_SETTINGS", null)),
            HealthSettingsRules.targets(sdkInt = 34, packageName = "com.karma.walk"),
        )
    }

    @Test
    fun `android 13 and earlier opens the Health Connect app's settings`() {
        assertEquals(
            listOf(HealthSettingsRules.Target("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS", null)),
            HealthSettingsRules.targets(sdkInt = 33, packageName = "com.karma.walk"),
        )
    }
}
