package com.gdelataillade.alarm.alarm

import com.gdelataillade.alarm.generated.AlarmApi
import com.gdelataillade.alarm.generated.AlarmTriggerApi
import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import com.gdelataillade.alarm.api.AlarmApiImpl
import com.gdelataillade.alarm.services.AlarmRingingLiveData
import io.flutter.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class AlarmPlugin : FlutterPlugin, ActivityAware {
    private var activity: Activity? = null

    companion object {
        private const val TAG = "AlarmPlugin"

        // Fork: 엔진마다 API 를 따로 기억하고 가장 나중에 붙은 엔진의 것을 쓴다([EngineRegistry]).
        // 헤드리스 엔진이 내려가도 앱 엔진의 API 는 남는다.
        private val triggerApis = EngineRegistry<BinaryMessenger, AlarmTriggerApi>()

        @JvmStatic
        val alarmTriggerApi: AlarmTriggerApi?
            get() = synchronized(triggerApis) { triggerApis.current }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        AlarmApi.setUp(binding.binaryMessenger, AlarmApiImpl(binding.applicationContext))
        synchronized(triggerApis) {
            triggerApis.attach(binding.binaryMessenger, AlarmTriggerApi(binding.binaryMessenger))
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        AlarmApi.setUp(binding.binaryMessenger, null)
        synchronized(triggerApis) { triggerApis.detach(binding.binaryMessenger) }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        AlarmRingingLiveData.instance.observe(
            binding.activity as LifecycleOwner,
            notificationObserver
        )
    }

    override fun onDetachedFromActivity() {
        activity = null
        AlarmRingingLiveData.instance.removeObserver(notificationObserver)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    private val notificationObserver = Observer<Boolean> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O_MR1) {
            Log.w(TAG, "Making app visible on lock screen is not supported on this version of Android.")
            return@Observer
        }
        val activity = activity ?: return@Observer
        if (it) {
            Log.d(TAG, "Making app visible on lock screen...")
            activity.setShowWhenLocked(true)
            activity.setTurnScreenOn(true)
            // The calls above already show the alarm over the lock screen; dismissing a
            // secure keyguard on top of that would only prompt the user to authenticate.
            val keyguardManager =
                activity.applicationContext.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            if (!keyguardManager.isDeviceSecure) {
                keyguardManager.requestDismissKeyguard(activity, null)
            }
        } else {
            Log.d(TAG, "Reverting making app visible on lock screen...")
            activity.setShowWhenLocked(false)
            activity.setTurnScreenOn(false)
        }
    }
}
