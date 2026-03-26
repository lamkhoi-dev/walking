package com.runly.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.runly.app/notification"
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
    }
}
