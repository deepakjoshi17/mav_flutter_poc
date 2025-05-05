package com.example.mav_flutter.mav_flutter.vm

import android.app.Application
import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.lifecycle.AndroidViewModel
import com.amazonaws.ivs.broadcast.*
import com.example.mav_flutter.mav_flutter.participant.ParticipantAdapter
import com.example.mav_flutter.mav_flutter.participant.StageParticipant
import kotlinx.coroutines.flow.MutableStateFlow

private const val TAG = "AmazonIVS"

// Main ViewModel
@RequiresApi(Build.VERSION_CODES.P)
class NativeViewModel(application: Application) : AndroidViewModel(application) {
    private val _participantAdapter = MutableStateFlow(ParticipantAdapter())
    val participantAdapter: ParticipantAdapter get() = _participantAdapter.value!!
    private val deviceDiscovery = DeviceDiscovery(application)
    private val screenCaptureManager = ScreenCaptureManager(application, deviceDiscovery)
    private val stageManager = StageManager(application, participantAdapter)
    private val streams = mutableListOf<LocalStageStream>()

    init {
        val localParticipant = StageParticipant(true, null)
        participantAdapter?.participantJoined(localParticipant)
    }

    public override fun onCleared() {
        stageManager.release()
        deviceDiscovery.release()
    }

    fun joinStage(token: String) {
        stageManager.joinStage(token, streams, false)
    }

    fun leaveStage() {
        stageManager.release()
    }

    fun startScreenShare(displayToken: String, intent: Intent) {
        val screenShareStreams = screenCaptureManager.startScreenCapture(intent)
        stageManager.joinStage(displayToken, screenShareStreams, true)
    }

    fun stopScreenShare() {
        screenCaptureManager.stopScreenCapture()
        stageManager.leaveScreenShareStage()
    }

    fun toggleMic() {
        streams.first { it.streamType == StageStream.Type.AUDIO }.muted = 
            !streams.first { it.streamType == StageStream.Type.AUDIO }.muted
        participantAdapter.muteAudio(streams.first { it.streamType == StageStream.Type.AUDIO }.muted)
    }

    fun toggleCamera() {
        streams.first { it.streamType == StageStream.Type.VIDEO }.muted = 
            !streams.first { it.streamType == StageStream.Type.VIDEO }.muted
        participantAdapter.muteVideo(streams.first { it.streamType == StageStream.Type.VIDEO }.muted)
    }

    internal fun permissionGranted() {
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

        // Update our local participant with these new streams
        participantAdapter.participantUpdated(null) {
            it.streams.clear()
            it.streams.addAll(streams)
        }
    }

    fun setPublishEnabled(enabled: Boolean) {
        stageManager.setPublishEnabled(enabled)
    }

    val canPublish: Boolean
        get() = streams.isNotEmpty()
}