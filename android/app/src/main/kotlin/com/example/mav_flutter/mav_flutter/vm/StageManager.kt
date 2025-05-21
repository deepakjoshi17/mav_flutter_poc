package com.example.mav_flutter.mav_flutter.vm

import android.app.Application
import android.os.Build
import android.util.Log
import android.widget.Toast
import androidx.annotation.RequiresApi
import com.amazonaws.ivs.broadcast.*
import com.example.mav_flutter.mav_flutter.participant.ParticipantAdapter
import kotlinx.coroutines.flow.MutableStateFlow

@RequiresApi(Build.VERSION_CODES.P)
class StageManager(
    private val application: Application,
    private val participantAdapter: ParticipantAdapter
) {
    private var mainStage: Stage? = null
    private var screenShareStage: Stage? = null
    private var publishEnabled = true
    @RequiresApi(Build.VERSION_CODES.P)
    private val _connectionState = MutableStateFlow(Stage.ConnectionState.DISCONNECTED)

    fun joinStage(token: String, streams: List<LocalStageStream>, isScreenShare: Boolean = false) {
        if (isScreenShare) {
            handleScreenShareStage(token, streams)
        } else {
            handleMainStage(token, streams)
        }
    }

    private fun handleMainStage(token: String, streams: List<LocalStageStream>) {
        if (_connectionState.value != Stage.ConnectionState.DISCONNECTED) {
            mainStage?.leave()
            mainStage?.release()
            mainStage = null
        }

        if (token.isEmpty()) {
            Toast.makeText(application, "Empty Token", Toast.LENGTH_SHORT).show()
            return
        }

        try {
            val newStage = createStage(token, streams)
            newStage.join()
            mainStage = newStage
        } catch (e: BroadcastException) {
            Log.e(TAG, "Failed to join main stage", e)
            Toast.makeText(application, "Failed to join stage: ${e.localizedMessage}", Toast.LENGTH_LONG).show()
            cleanupMainStage()
        }
    }

    private fun handleScreenShareStage(token: String, streams: List<LocalStageStream>) {
        if (screenShareStage != null) {
            screenShareStage?.leave()
            screenShareStage?.release()
            screenShareStage = null
        }

        try {
            val newStage = createStage(token, streams)
            newStage.join()
            screenShareStage = newStage
        } catch (e: BroadcastException) {
            Log.e(TAG, "Failed to join screen share stage", e)
            Toast.makeText(application, "Failed to join screen share stage: ${e.localizedMessage}", Toast.LENGTH_LONG).show()
            cleanupScreenShareStage()
        }
    }

    private fun createStage(token: String, streams: List<LocalStageStream>): Stage {
        return Stage(application, token, StageStrategyImpl(streams, publishEnabled)).apply {
            addRenderer(StageRendererImpl(participantAdapter, _connectionState))
        }
    }

    fun release() {
        cleanupMainStage()
        cleanupScreenShareStage()
    }

    private fun cleanupMainStage() {
        mainStage?.leave()
        mainStage?.release()
        mainStage = null
    }

    private fun cleanupScreenShareStage() {
        screenShareStage?.leave()
        screenShareStage?.release()
        screenShareStage = null
    }

    fun setPublishEnabled(enabled: Boolean) {
        publishEnabled = enabled
        mainStage?.refreshStrategy()
        screenShareStage?.refreshStrategy()
    }

    fun refreshStrategy() {
        mainStage?.refreshStrategy()
    }

    fun refreshScreenShareStrategy() {
        screenShareStage?.refreshStrategy()
    }

    fun leaveScreenShareStage() {
        cleanupScreenShareStage()
        participantAdapter.clearScreenShareParticipants()
    }

    companion object {
        private const val TAG = "StageManager-IVSAndroid"
    }
} 