package com.runly.app

import com.tiktok.TikTokBusinessSdk
import com.tiktok.appevents.base.TTBaseEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.runly.app/notification"
    private val TIKTOK_CHANNEL = "com.runly.app/tiktok"
    private lateinit var notificationHelper: StepNotificationHelper

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        notificationHelper = StepNotificationHelper(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showStepNotification" -> {
                        val steps = call.argument<Int>("steps") ?: 0
                        val goal = call.argument<Int>("goal") ?: 10000
                        val distanceKm = call.argument<String>("distanceKm") ?: "0.0"
                        val calories = call.argument<String>("calories") ?: "0"
                        val minutes = call.argument<String>("minutes") ?: "0"
                        val progress = call.argument<Int>("progress") ?: 0
                        val motivation = call.argument<String>("motivation") ?: ""
                        val isWalking = call.argument<Boolean>("isWalking") ?: false

                        notificationHelper.showStepNotification(
                            steps, goal, distanceKm, calories,
                            minutes, progress, motivation, isWalking
                        )
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TIKTOK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "trackEvent" -> {
                        val name = call.argument<String>("eventName")
                        if (name == null) {
                            result.error("bad_args", "eventName required", null)
                            return@setMethodCallHandler
                        }
                        val eventId = call.argument<String>("eventId")
                        val builder = if (eventId != null) {
                            TTBaseEvent.newBuilder(name, eventId)
                        } else {
                            TTBaseEvent.newBuilder(name)
                        }
                        call.argument<Map<String, Any?>>("properties")?.forEach { (key, value) ->
                            value?.let { builder.addProperty(key, it) }
                        }
                        TikTokBusinessSdk.trackTTEvent(builder.build())
                        result.success(null)
                    }
                    "identify" -> {
                        TikTokBusinessSdk.identify(
                            call.argument<String>("externalId"),
                            call.argument<String>("userName"),
                            call.argument<String>("phone"),
                            call.argument<String>("email")
                        )
                        result.success(null)
                    }
                    "logout" -> {
                        TikTokBusinessSdk.logout()
                        result.success(null)
                    }
                    // App Tracking Transparency is iOS-only; nothing to do on Android.
                    "requestTracking" -> result.success(null)
                    else -> result.notImplemented()
                }
            }
    }
}
