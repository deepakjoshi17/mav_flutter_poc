package com.example.mav_flutter.mav_flutter.vm

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import androidx.annotation.RequiresApi
import com.amazonaws.ivs.broadcast.*
import com.amazonaws.ivs.broadcast.BroadcastConfiguration.Vec2
import com.amazonaws.ivs.webrtc.ScreenCapturerAndroid

@RequiresApi(Build.VERSION_CODES.P)
class ScreenCaptureManager(
    private val context: Context,
    private val deviceDiscovery: DeviceDiscovery
) {
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var screenCaptureAndroid: ScreenCapturerAndroid? = null
    private val screenShareStream = mutableListOf<LocalStageStream>()

    private val mediaProjectionCallback = object : MediaProjection.Callback() {
        override fun onStop() {
            super.onStop()
            Log.d(TAG, "MediaProjection stopped")
            stopScreenCapture()
        }
    }

    fun startScreenCapture(intent: Intent): List<LocalStageStream> {
        val windowManager = context.getSystemService(WindowManager::class.java)
        val displayMetrics = DisplayMetrics()
        windowManager.defaultDisplay.getRealMetrics(displayMetrics)
        
        val width = 720
        val height = 1280
        val dpi = displayMetrics.densityDpi

        val mediaProjectionManager = context.getSystemService(MediaProjectionManager::class.java)
        mediaProjection = mediaProjectionManager.getMediaProjection(Activity.RESULT_OK, intent)
        mediaProjection?.registerCallback(mediaProjectionCallback, null)

        val source = deviceDiscovery.createImageInputSource(Vec2(width.toFloat(), height.toFloat()))
        val surface = source.inputSurface

        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenCapture",
            width,
            height,
            dpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            surface,
            object : VirtualDisplay.Callback() {
                override fun onPaused() {
                    super.onPaused()
                    Log.d(TAG, "VirtualDisplay paused")
                }

                override fun onResumed() {
                    super.onResumed()
                    Log.d(TAG, "VirtualDisplay resumed")
                }

                override fun onStopped() {
                    super.onStopped()
                    Log.d(TAG, "VirtualDisplay stopped")
                    stopScreenCapture()
                }
            },
            null
        )

        val stream = ImageLocalStageStream(source)
        val stageVideoConfiguration = StageVideoConfiguration().apply {
            size = Vec2(width.toFloat(), height.toFloat())
            targetFramerate = 30
        }
        stream.setVideoConfiguration(stageVideoConfiguration)
        screenShareStream.clear()
        screenShareStream.add(stream)

        return screenShareStream
    }

    fun stopScreenCapture() {
        screenCaptureAndroid?.stopCapture()
        screenCaptureAndroid = null
        mediaProjection?.unregisterCallback(mediaProjectionCallback)
        mediaProjection?.stop()
        mediaProjection = null
        virtualDisplay?.release()
        virtualDisplay = null
        screenShareStream.clear()
    }

    companion object {
        private const val TAG = "AmazonIVS"
    }
} 