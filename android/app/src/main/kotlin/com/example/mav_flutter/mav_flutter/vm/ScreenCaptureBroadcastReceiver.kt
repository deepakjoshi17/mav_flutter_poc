package com.example.mav_flutter.mav_flutter.vm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi
import com.example.mav_flutter.mav_flutter.screen_share.MyMediaProjectionService
import com.example.mav_flutter.mav_flutter.screen_share.MyMediaProjectionService.Companion.EXTRA_DATA
import com.example.mav_flutter.mav_flutter.screen_share.MyMediaProjectionService.Companion.EXTRA_RESULT_CODE

@RequiresApi(Build.VERSION_CODES.O)
class ScreenCaptureBroadcastReceiver(private val callback: (Intent) -> Unit) : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (MyMediaProjectionService.ACTION_START_MEDIA_PROJECTION == intent.action) {
            val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, 0)
            val data = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(EXTRA_DATA, Intent::class.java)
            } else {
                intent.getParcelableExtra(EXTRA_DATA)
            }
            if (resultCode != 0 && data != null) {
                callback(data)
            }
        }
    }
}