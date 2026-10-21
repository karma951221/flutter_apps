package com.karma.walk

import android.app.Activity
import android.app.AlertDialog
import android.content.res.Configuration
import android.os.Bundle

/**
 * Health Connect 권한 창의 "개인정보처리방침" · 이유 보기 링크가 여는 안내. 걸음만 읽고 저장 · 전송하지
 * 않는다는 한 문단을 대화상자로 보이고 닫으면 끝난다.
 *
 * 예전에는 이 링크가 MainActivity 로 와서 Health Connect 태스크 위에 Flutter 앱이 하나 더 떴고,
 * 그 앱이 다시 권한을 물어 권한 창이 겹쳤다(2026-10-21 QA ⑦). Flutter 엔진 없이 끝나는 화면으로 받는다.
 */
class HealthPrivacyActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val night = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
            Configuration.UI_MODE_NIGHT_YES
        val theme = if (night) {
            android.R.style.Theme_DeviceDefault_Dialog_Alert
        } else {
            android.R.style.Theme_DeviceDefault_Light_Dialog_Alert
        }
        AlertDialog.Builder(this, theme)
            .setTitle(R.string.health_privacy_title)
            .setMessage(R.string.health_privacy_body)
            .setPositiveButton(android.R.string.ok, null)
            .setOnDismissListener { finish() }
            .show()
    }
}
