package com.runly.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat

class StepNotificationHelper(private val context: Context) {

    companion object {
        const val CHANNEL_ID = "step_counter_channel"
        const val NOTIFICATION_ID = 200
    }

    init {
        createChannel()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Đếm bước chân",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Hiển thị tiến trình đếm bước chân"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    fun showStepNotification(
        steps: Int,
        goal: Int,
        distanceKm: String,
        calories: String,
        minutes: String,
        progress: Int,
        motivation: String,
        isWalking: Boolean
    ) {
        // Expanded custom layout with real icons
        val expandedView = RemoteViews(context.packageName, R.layout.notification_expanded)
        expandedView.setTextViewText(R.id.tv_distance_value, "$distanceKm km")
        expandedView.setTextViewText(R.id.tv_calories_value, "$calories cal")
        expandedView.setTextViewText(R.id.tv_time_value, "$minutes phút")
        expandedView.setTextViewText(R.id.tv_goal_value, "$progress%")
        expandedView.setProgressBar(R.id.progress_bar, 100, progress.coerceIn(0, 100), false)
        expandedView.setTextViewText(R.id.tv_motivation, motivation)

        // Format step count
        val formattedSteps = formatNumber(steps)
        val statusText = if (isWalking) "Đang đi bộ" else "Đang theo dõi"

        // Tap to open app
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_SINGLE_TOP }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("$formattedSteps bước")
            .setContentText("$distanceKm km  ·  $calories cal  ·  $minutes phút")
            .setSubText(statusText)
            .setCustomBigContentView(expandedView)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setColor(0xFF2E7D32.toInt())
            .setColorized(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSound(null)
            .setVibrate(null)

        val manager = context.getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, builder.build())
    }

    private fun formatNumber(n: Int): String {
        if (n < 1000) return n.toString()
        return String.format("%,d", n).replace(',', '.')
    }
}
