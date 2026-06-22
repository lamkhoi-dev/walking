package com.runly.app

import android.app.Application
import android.content.pm.ApplicationInfo
import com.tiktok.TikTokBusinessSdk
import com.tiktok.TikTokBusinessSdk.TTConfig

/**
 * Custom Application that initializes the TikTok Business (App Events) SDK as
 * early as possible so automatic Install / Launch events are captured.
 *
 * IDs come from TikTok Events Manager:
 *  - appId   = "ID Ứng dụng"
 *  - ttAppId = "ID ứng dụng TikTok"
 */
class RunlyApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        val config = TTConfig(applicationContext)
            .setAppId(TIKTOK_APP_ID)
            .setTTAppId(TIKTOK_TT_APP_ID)

        val isDebuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (isDebuggable) {
            TikTokBusinessSdk.enableDebugMode()
        }

        TikTokBusinessSdk.initializeSdk(config)
        // Ensure the tracking pipeline is active (no-op if auto-start already ran).
        TikTokBusinessSdk.startTrack()
    }

    companion object {
        private const val TIKTOK_APP_ID = "6760386944"
        private const val TIKTOK_TT_APP_ID = "7653820676664147975"
    }
}
