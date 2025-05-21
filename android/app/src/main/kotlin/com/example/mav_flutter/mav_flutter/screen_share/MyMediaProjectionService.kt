package com.example.mav_flutter.mav_flutter.screen_share

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.amazonaws.ivs.broadcast.*
import com.example.mav_flutter.mav_flutter.MainActivity
import com.example.mav_flutter.mav_flutter.R
import com.example.mav_flutter.mav_flutter.vm.ScreenCaptureBroadcastReceiver


@RequiresApi(Build.VERSION_CODES.O)
class MyMediaProjectionService : SystemCaptureService() {
    private val CHANNEL_ID = "MediaProjectionServiceChannel"

    companion object {
        const val ACTION_START_MEDIA_PROJECTION = "com.example.mav_flutter.ACTION_START_MEDIA_PROJECTION"
        const val EXTRA_RESULT_CODE = "resultCode"
        const val EXTRA_DATA = "data"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, getNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        }
        else {
            startForeground(1, getNotification())
        }

        when (intent?.action) {
            ACTION_START_MEDIA_PROJECTION -> {
                val resultCode = intent.getIntExtra("resultCode", -1)

                val broadcastIntent = Intent(this, ScreenCaptureBroadcastReceiver::class.java)
                broadcastIntent.setAction(ACTION_START_MEDIA_PROJECTION)
                broadcastIntent.putExtra("resultCode", resultCode)
                val mpIntent: Intent? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(EXTRA_DATA, Intent::class.java)
                }
                else {
                    intent.getParcelableExtra(EXTRA_DATA)
                }
                if(mpIntent != null) broadcastIntent.putExtra(EXTRA_DATA, mpIntent)

                LocalBroadcastManager.getInstance(this).sendBroadcast(broadcastIntent)
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun getNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Screen Sharing Active")
            .setContentText("Your screen is being shared via Amazon IVS")
            .setSmallIcon(R.drawable.ic_launcher_background)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun createNotificationChannel() {
        val serviceChannel = NotificationChannel(
            CHANNEL_ID, "Screen Capture Service",
            NotificationManager.IMPORTANCE_LOW
        )
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(serviceChannel)
    }
}