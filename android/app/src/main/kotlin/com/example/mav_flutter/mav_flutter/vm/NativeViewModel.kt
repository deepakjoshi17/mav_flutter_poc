package com.example.mav_flutter.mav_flutter.vm

import android.app.Activity
import android.app.Application
import android.app.Notification
import android.content.ContentValues.TAG
import android.content.Context
import android.content.Context.*
import android.content.Intent
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.util.Log
import android.view.Surface
import android.view.TextureView
import android.view.WindowManager
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.lifecycle.AndroidViewModel
import com.amazonaws.ivs.broadcast.AudioLocalStageStream
import com.amazonaws.ivs.broadcast.BroadcastConfiguration
import com.amazonaws.ivs.broadcast.BroadcastConfiguration.Vec2
import com.amazonaws.ivs.broadcast.BroadcastException
import com.amazonaws.ivs.broadcast.BroadcastSession
import com.amazonaws.ivs.broadcast.Device
import com.amazonaws.ivs.broadcast.DeviceDiscovery
import com.amazonaws.ivs.broadcast.ImageLocalStageStream
import com.amazonaws.ivs.broadcast.LocalStageStream
import com.amazonaws.ivs.broadcast.ParticipantInfo
import com.amazonaws.ivs.broadcast.Presets.Devices
import com.amazonaws.ivs.broadcast.Stage
import com.amazonaws.ivs.broadcast.StageRenderer
import com.amazonaws.ivs.broadcast.StageStream
import com.amazonaws.ivs.broadcast.StageVideoConfiguration
import com.amazonaws.ivs.broadcast.SystemCaptureService.STOP_FOREGROUND_REMOVE
import com.amazonaws.ivs.webrtc.CapturerObserver
import com.amazonaws.ivs.webrtc.EglBase
import com.amazonaws.ivs.webrtc.ScreenCapturerAndroid
import com.amazonaws.ivs.webrtc.SurfaceTextureHelper
import com.amazonaws.ivs.webrtc.VideoFrame
import com.example.mav_flutter.mav_flutter.participant.ParticipantAdapter
import com.example.mav_flutter.mav_flutter.participant.StageParticipant
import com.example.mav_flutter.mav_flutter.screen_share.BroadcastSystemCaptureService
import com.example.mav_flutter.mav_flutter.screen_share.NotificationActivity
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

private const val NOTIFICATION_CHANNEL_ID = "notificationId"
private const val NOTIFICATION_CHANNEL_NAME = "notificationName"
private const val TAG = "AmazonIVS"

@RequiresApi(Build.VERSION_CODES.P)
class NativeViewModel(application: Application) : AndroidViewModel(application), Stage.Strategy, StageRenderer {

    /// If `canPublish` is `false`, the sample application will not ask for permissions or publish to the stage
    /// This will be a view-only participant.
    val canPublish = true

    // App State
    internal val participantAdapter = ParticipantAdapter()

    private val _connectionState = MutableStateFlow(Stage.ConnectionState.DISCONNECTED)

    val connectionState = _connectionState.asStateFlow()

    private var publishEnabled: Boolean = false

        set(value) {
            field = value
            // Because the strategy returns the value of `checkboxPublish.isChecked`, just call `refreshStrategy`.
            stage?.refreshStrategy()
        }

    // Amazon IVS SDK resources
    private var deviceDiscovery: DeviceDiscovery? = null
    private var stage: Stage? = null
    private var ssStage: Stage? = null
    private var streams = mutableListOf<LocalStageStream>()
    private var screenShareStream = mutableListOf<LocalStageStream>()
    private var screenCaptureAndroid: ScreenCapturerAndroid? = null
//    private var broadcastSession: BroadcastSession? = null

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private lateinit var broadcastSession: BroadcastSession
    private lateinit var stageStream: ImageLocalStageStream

    init {
        deviceDiscovery = DeviceDiscovery(application)

        if (canPublish) {
            // Create a local participant immediately to render our camera preview and microphone stats
            val localParticipant = StageParticipant(true, null)
            participantAdapter.participantJoined(localParticipant)
        }
    }

    private fun muteAudio(mute: Boolean) {
        streams.first { it.streamType == StageStream.Type.AUDIO }.muted = mute
        participantAdapter.muteAudio(mute)
    }

    private fun muteVideo(mute: Boolean) {
        streams.first { it.streamType == StageStream.Type.VIDEO }.muted = mute
        participantAdapter.muteVideo(mute)
        stage?.refreshStrategy()
    }

    public override fun onCleared() {
        stage?.release()
        ssStage?.release()
        deviceDiscovery?.release()
        deviceDiscovery = null
        super.onCleared()
    }

    fun leaveStage() {
        stage?.leave()
        ssStage?.leave()
    }

    internal fun joinStage(token: String, audioMuted: Boolean, videoMuted: Boolean) {
        if (_connectionState.value != Stage.ConnectionState.DISCONNECTED) {
            // If we're already connected to a stage, leave it.
            stage?.leave()
        } else {
            if (token.isEmpty()) {
                Toast.makeText(getApplication(), "Empty Token", Toast.LENGTH_SHORT).show()
                return
            }
            try {
                // Destroy the old stage first before creating a new one.
                stage?.release()
                val stage = Stage(getApplication(), token, this)
                stage.addRenderer(this)
                stage.join()
                this.stage = stage
            } catch (e: BroadcastException) {
                Toast.makeText(getApplication(), "Failed to join stage ${e.localizedMessage}", Toast.LENGTH_LONG).show()
                e.printStackTrace()
            }
        }
    }

    internal fun startScreenCapture(context: Activity, displayToken: String, intent: Intent) {

        val mediaProjectionManager =
            context.applicationContext.getSystemService("media_projection") as MediaProjectionManager

        val source = deviceDiscovery?.createImageInputSource(Vec2(1280f, 720f))

        screenCaptureAndroid = ScreenCapturerAndroid(
            mediaProjectionManager.createScreenCaptureIntent(),
            screenShareCallback
        )

        val surfaceTextureHelper = SurfaceTextureHelper.create("ScreenCapture", EglBase.create().eglBaseContext)
        screenCaptureAndroid?.initialize(
            surfaceTextureHelper,
            context.applicationContext,
            capturerObserver
        )

        val width: Int
        val height: Int
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val windowMetrics = context.windowManager.currentWindowMetrics
            width = windowMetrics.bounds.width()
            height = windowMetrics.bounds.height()
        } else {
            val manager = context.getSystemService(WINDOW_SERVICE) as WindowManager
            val display = manager.defaultDisplay
            width = display.width
            height = display.height
        }

        screenCaptureAndroid?.mediaProjection?.createVirtualDisplay(
            "ScreenCapture",
            width,
            height,
            1,
            0,
            source?.inputSurface,
            null,
            null
        )
//        screenCaptureAndroid?.startCapture(width, height, 30)

        streams.add(ImageLocalStageStream(source!!))
        /*ssStage?.release()
        val stage = Stage(getApplication(), displayToken, this)
        stage.addRenderer(this)
        stage.join()

        Log.d(TAG, "------> Joined stage")
        ssStage = stage*/
        println("*****Creating session with intent $intent")

        createSession(context)

        println("*****Created session")

        /*var notification: Notification? = null
        if (Build.VERSION.SDK_INT >= 26) {
            notification = createNotification(context)
        } else {
            Toast.makeText(
                getApplication(),
                "Screen capture requires Android 8.0 or higher",
                Toast.LENGTH_LONG
            ).show()
            return
        }*/

        println("*****Created notification")

        /*broadcastSession?.createSystemCaptureSources(
            intent,
            BroadcastSystemCaptureService::class.java,
            notification
        ) { devices: List<Device> ->
            Log.d(TAG, "------> Screen capture started")
            devices
                .filter { it.descriptor.type == Device.Descriptor.DeviceType.SCREEN }
                .forEach { _ ->
                    Log.d(TAG, "------> Adding devices via ImageLocalStageStream")

                    val source = deviceDiscovery?.createImageInputSource(Vec2(1280f, 720f))

                    if(source != null) {
                        streams.add(ImageLocalStageStream(source))
                        ssStage?.refreshStrategy()
                    }
                }

            Log.d(TAG, "------> Creating stage")
            ssStage?.release()
            val stage = Stage(getApplication(), displayToken, this)
            stage.addRenderer(this)
            stage.join()

            Log.d(TAG, "------> Joined stage")
            ssStage = stage
        }*/
    }

    private fun createNotification(context: Activity) = broadcastSession?.createServiceNotificationBuilder(
        NOTIFICATION_CHANNEL_ID,
        NOTIFICATION_CHANNEL_NAME,
        Intent(context, NotificationActivity::class.java)
    )?.build()

    /*internal fun stopScreenShare() {
        if(screenCaptureAndroid != null) {
            screenCaptureAndroid?.stopCapture()
            screenCaptureAndroid = null
        }
    }*/

    private val capturerObserver = object : CapturerObserver {
        override fun onCapturerStarted(p0: Boolean) {
            println("*****onCapturerStarted")
        }

        override fun onCapturerStopped() {
            println("*****onCapturerStopped")
        }

        override fun onFrameCaptured(p0: VideoFrame?) {
            println("*****onFrameCaptured")
        }

    }

    private val screenShareCallback = object : android.media.projection.MediaProjection.Callback() {
        override fun onCapturedContentResize(width: Int, height: Int) {
            super.onCapturedContentResize(width, height)
            println("*****onCapturedContentResize")
        }

        override fun onCapturedContentVisibilityChanged(isVisible: Boolean) {
            super.onCapturedContentVisibilityChanged(isVisible)
            println("*****onCapturedContentVisibilityChanged")
        }
    }

    internal fun setPublishEnabled(enabled: Boolean) {
        publishEnabled = enabled
    }

    internal fun permissionGranted() {
        val deviceDiscovery = deviceDiscovery ?: return
        streams.clear()
        val devices = deviceDiscovery.listLocalDevices()
        // Camera
        devices
            .filter { it.descriptor.type == Device.Descriptor.DeviceType.CAMERA }
            .maxByOrNull { it.descriptor.position == Device.Descriptor.Position.FRONT }
            ?.let { streams.add(ImageLocalStageStream(it)) }
        // Microphone
        devices
            .filter { it.descriptor.type == Device.Descriptor.DeviceType.MICROPHONE }
            .maxByOrNull { it.descriptor.isDefault }
            ?.let { streams.add(AudioLocalStageStream(it)) }

        stage?.refreshStrategy()

        // Update our local participant with these new streams
        participantAdapter.participantUpdated(null) {
            it.streams.clear()
            it.streams.addAll(streams)
        }
    }

    //region Stage.Strategy
    override fun stageStreamsToPublishForParticipant(
        stage: Stage,
        participantInfo: ParticipantInfo
    ): MutableList<LocalStageStream> {
        // Return the camera and microphone to be published.
        // This is only called if `shouldPublishFromParticipant` returns true.
        return streams
    }

    override fun shouldPublishFromParticipant(stage: Stage, participantInfo: ParticipantInfo): Boolean {
        println("shouldPublishFromParticipant")
        return publishEnabled
    }

    override fun shouldSubscribeToParticipant(stage: Stage, participantInfo: ParticipantInfo): Stage.SubscribeType {
        // Subscribe to both audio and video for all publishing participants.
        return Stage.SubscribeType.AUDIO_VIDEO
    }
    //endregion

    //region StageRenderer
    override fun onError(exception: BroadcastException) {
        Toast.makeText(getApplication(), "onError ${exception.localizedMessage}", Toast.LENGTH_LONG).show()
        Log.e("BasicRealTime", "onError $exception")
    }

    override fun onConnectionStateChanged(
        stage: Stage,
        connectionState: Stage.ConnectionState,
        exception: BroadcastException?
    ) {
        _connectionState.value = connectionState
    }

    override fun onParticipantJoined(stage: Stage, participantInfo: ParticipantInfo) {
        if (participantInfo.isLocal) {
            // If this is the local participant joining the stage, update the participant with a null ID because we
            // manually added that participant when setting up our preview
            participantAdapter.participantUpdated(null) {
                it.participantId = participantInfo.participantId
            }
        } else {
            // If they are not local, add them normally
            participantAdapter.participantJoined(
                StageParticipant(
                    participantInfo.isLocal,
                    participantInfo.participantId
                )
            )
        }
    }

    override fun onParticipantLeft(stage: Stage, participantInfo: ParticipantInfo) {
        if (participantInfo.isLocal) {
            // If this is the local participant leaving the stage, update the ID but keep it around because
            // we want to keep the camera preview active
            participantAdapter.participantUpdated(participantInfo.participantId) {
                it.participantId = null
            }
        } else {
            // If they are not local, have them leave normally
            participantAdapter.participantLeft(participantInfo.participantId)
        }
    }

    override fun onParticipantPublishStateChanged(
        stage: Stage,
        participantInfo: ParticipantInfo,
        publishState: Stage.PublishState
    ) {
        // Update the publishing state of this participant
        participantAdapter.participantUpdated(participantInfo.participantId) {
            it.publishState = publishState
        }
    }

    override fun onParticipantSubscribeStateChanged(
        stage: Stage,
        participantInfo: ParticipantInfo,
        subscribeState: Stage.SubscribeState
    ) {
        // Update the subscribe state of this participant
        participantAdapter.participantUpdated(participantInfo.participantId) {
            it.subscribeState = subscribeState
        }
    }

    override fun onStreamsAdded(stage: Stage, participantInfo: ParticipantInfo, streams: MutableList<StageStream>) {
        // We don't want to take any action for the local participant because we track those streams locally
        if (participantInfo.isLocal) {
            return
        }
        // For remote participants, add these new streams to that participant's streams array.
        participantAdapter.participantUpdated(participantInfo.participantId) {
            it.streams.addAll(streams)
        }
    }

    override fun onStreamsRemoved(stage: Stage, participantInfo: ParticipantInfo, streams: MutableList<StageStream>) {
        // We don't want to take any action for the local participant because we track those streams locally
        if (participantInfo.isLocal) {
            return
        }
        // For remote participants, remove these streams from that participant's streams array.
        participantAdapter.participantUpdated(participantInfo.participantId) {
            it.streams.removeAll(streams)
        }
    }

    override fun onStreamsMutedChanged(
        stage: Stage,
        participantInfo: ParticipantInfo,
        streams: MutableList<StageStream>
    ) {
        // We don't want to take any action for the local participant because we track those streams locally
        if (participantInfo.isLocal) {
            return
        }
        // For remote participants, notify the adapter that the participant has been updated. There is no need to modify
        // the `streams` property on the `StageParticipant` because it is the same `StageStream` instance. Just
        // query the `isMuted` property again.
        participantAdapter.participantUpdated(participantInfo.participantId) {}
    }

    fun toggleMic() {
        muteAudio(!streams.first { it.streamType == StageStream.Type.AUDIO }.muted)
    }

    fun toggleCamera() {
        muteVideo(!streams.first { it.streamType == StageStream.Type.VIDEO }.muted)
    }
    //endregion

    private fun createSession(context: Activity) {
        broadcastSession = BroadcastSession(context.applicationContext, null, BroadcastConfiguration(), null)
    }

    fun startScreenShare(context: Context, displayToken: String, intent: Intent) {
        val displayMetrics = context.resources.displayMetrics
        val width = displayMetrics.widthPixels
        val height = displayMetrics.heightPixels
        val dpi = displayMetrics.densityDpi

        val source = deviceDiscovery?.createImageInputSource(Vec2(1280f, 720f))
        val surface = source?.inputSurface

        ssStage?.release()

        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenCapture",
            width,
            height,
            dpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            surface, null, null,
        )

        screenShareStream.add(ImageLocalStageStream(source!!))

        val stage = Stage(getApplication(), displayToken, object : Stage.Strategy {
            override fun stageStreamsToPublishForParticipant(
                stage: Stage,
                participantInfo: ParticipantInfo
            ): MutableList<LocalStageStream> {
                return screenShareStream
            }

            override fun shouldPublishFromParticipant(
                stage: Stage,
                participantInfo: ParticipantInfo
            ): Boolean {
                return true
            }

            override fun shouldSubscribeToParticipant(
                stage: Stage,
                participantInfo: ParticipantInfo
            ): Stage.SubscribeType {
                return Stage.SubscribeType.AUDIO_VIDEO
            }
        })
        stage.addRenderer(object : StageRenderer {
            override fun onError(exception: BroadcastException) {
                Toast.makeText(
                    getApplication(),
                    "onError ${exception.localizedMessage}",
                    Toast.LENGTH_LONG
                ).show()
                Log.e("BasicRealTime", "onError $exception")
            }

            override fun onConnectionStateChanged(
                stage: Stage,
                connectionState: Stage.ConnectionState,
                exception: BroadcastException?
            ) {
                _connectionState.value = connectionState
            }
        })
        stage.join()

        Log.d(TAG, "------> Joined stage")
        ssStage = stage

//        streams.add(ImageLocalStageStream(source!!))
        ssStage?.refreshStrategy()

        Log.d("ScreenCaptureService", "Screen streaming started")
    }

    fun stopScreenShare() {
        virtualDisplay?.release()
        mediaProjection?.stop()
        ssStage?.release()
//        stopForeground(STOP_FOREGROUND_REMOVE)
//        stopSelf()
    }
}