package com.example.mav_flutter.mav_flutter.screen_share

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.Surface
import android.view.TextureView
import android.view.WindowManager
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.amazonaws.ivs.broadcast.*
import com.amazonaws.ivs.webrtc.CapturerObserver
import com.amazonaws.ivs.webrtc.ScreenCapturerAndroid
import com.amazonaws.ivs.webrtc.SurfaceTextureHelper
import com.amazonaws.ivs.webrtc.VideoFrame
import com.example.mav_flutter.mav_flutter.MainActivity
import com.example.mav_flutter.mav_flutter.MainActivity.MyBroadcastReceiver
import com.example.mav_flutter.mav_flutter.R


@RequiresApi(Build.VERSION_CODES.O)
class MyMediaProjectionService : SystemCaptureService() {
    private val CHANNEL_ID = "MediaProjectionServiceChannel"
    private lateinit var mediaProjectionManager: MediaProjectionManager
    private var screenCaptureAndroid: ScreenCapturerAndroid? = null

    companion object {
        const val ACTION_START_MEDIA_PROJECTION = "com.example.mav_flutter.ACTION_START_MEDIA_PROJECTION"
        const val EXTRA_RESULT_CODE = "resultCode"
        const val EXTRA_DATA = "data"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        mediaProjectionManager = applicationContext.getSystemService("media_projection") as MediaProjectionManager
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

                val broadcastIntent = Intent(this, MyBroadcastReceiver::class.java)
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

//                startScreenShare()
            }
        }
        return START_STICKY
    }

    private fun startScreenCapture(context: Context) {

        screenCaptureAndroid = ScreenCapturerAndroid(mediaProjectionManager.createScreenCaptureIntent(), screenShareCallback)

        val surfaceTextureHelper = SurfaceTextureHelper.create("ScreenCapture", null)
        screenCaptureAndroid?.initialize(surfaceTextureHelper, applicationContext, capturerObserver)

        val width: Int
        val height: Int
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val manager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            manager.currentWindowMetrics.bounds.also {
                width = it.width()
                height = it.height()
            }
        } else {
            val manager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val display = manager.defaultDisplay
            width = display.width
            height = display.height
        }
        screenCaptureAndroid?.startCapture(width, height, 30)
    }

    private val screenShareCallback = object : android.media.projection.MediaProjection.Callback() {
        override fun onCapturedContentResize(width: Int, height: Int) {
            super.onCapturedContentResize(width, height)
        }

        override fun onCapturedContentVisibilityChanged(isVisible: Boolean) {
            super.onCapturedContentVisibilityChanged(isVisible)
        }
    }

    private fun stopScreenCapture() {
        if(screenCaptureAndroid != null) {
            screenCaptureAndroid?.stopCapture()
            screenCaptureAndroid = null
        }
    }

    private val capturerObserver = object : CapturerObserver {
        override fun onCapturerStarted(p0: Boolean) {
            println("onCapturerStarted")
        }

        override fun onCapturerStopped() {
            println("onCapturerStopped")
        }

        override fun onFrameCaptured(p0: VideoFrame?) {
            println("onFrameCaptured")
        }

    }

    override fun onDestroy() {
        super.onDestroy()
        stopScreenCapture()
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