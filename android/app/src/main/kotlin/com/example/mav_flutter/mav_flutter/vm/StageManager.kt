package com.example.mav_flutter.mav_flutter.vm

import android.app.Application
import android.os.Build
import android.util.Log
import android.widget.Toast
import androidx.annotation.RequiresApi
import com.amazonaws.ivs.broadcast.*
import com.amazonaws.ivs.broadcast.Stage.SubscribeType
import com.example.mav_flutter.mav_flutter.participant.ParticipantAdapter
import com.example.mav_flutter.mav_flutter.participant.StageParticipant
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

@RequiresApi(Build.VERSION_CODES.P)
class StageManager(
    private val application: Application,
    private val participantAdapter: ParticipantAdapter
) {
    private var stage: Stage? = null
    private var ssStage: Stage? = null
    private var publishEnabled = true
    @RequiresApi(Build.VERSION_CODES.P)
    private val _connectionState = MutableStateFlow(Stage.ConnectionState.DISCONNECTED)
    val connectionState = _connectionState.asStateFlow()

    private inner class StageRendererImpl(
        private val participantAdapter: ParticipantAdapter,
        private val connectionState: MutableStateFlow<Stage.ConnectionState>
    ) : StageRenderer {
        override fun onParticipantPublishStateChanged(
            stage: Stage,
            participant: ParticipantInfo,
            publishState: Stage.PublishState
        ) {
            println("-------------->>>>>>> Publish state changed: ${publishState.name}")
            if (participant.isLocal) {
                val localParticipant = participantAdapter.participants.firstOrNull { it.isLocal }
                if (localParticipant != null) {
                    localParticipant.publishState = publishState
                    participantAdapter.notifyItemChanged(0, localParticipant)
                }
            } else {
                val existingParticipant = participantAdapter.participants.firstOrNull { it.participantId == participant.participantId }
                if (existingParticipant != null) {
                    existingParticipant.publishState = publishState
                    participantAdapter.notifyItemChanged(participantAdapter.participants.indexOf(existingParticipant), existingParticipant)
                } else if (publishState == Stage.PublishState.PUBLISHED) {
                    val newParticipant = StageParticipant(false, participant.participantId, participant.attributes)
                    newParticipant.publishState = publishState
                    participantAdapter.participantJoined(newParticipant)
                }
            }
        }

        override fun onParticipantSubscribeStateChanged(
            stage: Stage,
            participant: ParticipantInfo,
            subscribeState: Stage.SubscribeState
        ) {
            println("-------------->>>>>>> Subscribe state changed: ${subscribeState.name}")
            if (!participant.isLocal) {
                val existingParticipant = participantAdapter.participants.firstOrNull { it.participantId == participant.participantId }
                if (existingParticipant != null) {
                    existingParticipant.subscribeState = subscribeState
                    participantAdapter.notifyItemChanged(participantAdapter.participants.indexOf(existingParticipant), existingParticipant)
                }
            }
        }

        override fun onStreamsMutedChanged(
            stage: Stage,
            participant: ParticipantInfo,
            streams: MutableList<StageStream>
        ) {
            println("-------------->>>>>>> Streams muted changed: ${streams.joinToString(", ") { it.device.tag }}")
            if (!participant.isLocal) {
                val existingParticipant = participantAdapter.participants.firstOrNull { it.participantId == participant.participantId }
                if (existingParticipant != null) {
                    existingParticipant.streams.clear()
                    existingParticipant.streams.addAll(streams)
                    participantAdapter.notifyItemChanged(participantAdapter.participants.indexOf(existingParticipant), existingParticipant)
                }
            }
        }

        override fun onConnectionStateChanged(
            stage: Stage,
            connectionState: Stage.ConnectionState,
            exception: BroadcastException?
        ) {
            println("-------------->>>>>>> Connection state changed: ${connectionState.name}")
            this.connectionState.value = connectionState
            if (connectionState == Stage.ConnectionState.DISCONNECTED) {
                // Clear all participants except the local one
                val localParticipant = participantAdapter.participants.firstOrNull { it.isLocal }
                participantAdapter.participants.clear()
                if (localParticipant != null) {
                    participantAdapter.participants.add(localParticipant)
                }
                participantAdapter.notifyDataSetChanged()
            }
        }

        override fun onError(exception: BroadcastException) {
            Log.e(TAG, "Stage error: ${exception.localizedMessage}")
        }

        override fun onParticipantJoined(stage: Stage, participant: ParticipantInfo) {
            println("-------------->>>>>>> Participant joined: ${participant.participantId}")
            if (participant.isLocal) {
                participantAdapter.participantUpdated(null) {
                    it.participantId = participant.participantId
                }
            } else {
                println("-------------->>>>>>> Remote Participant joined: ${participant.attributes}")
                participantAdapter.participantJoined(
                    StageParticipant(participant.isLocal, participant.participantId, participant.attributes)
                )
            }
        }

        override fun onParticipantLeft(stage: Stage, participant: ParticipantInfo) {
            println("-------------->>>>>>> Participant left: ${participant.participantId}")
            if (participant.isLocal) {
                participantAdapter.participantUpdated(participant.participantId) {
                    it.participantId = null
                }
            } else {
                println("-------------->>>>>>> Remote Participant left: ${participant.participantId}")
                participantAdapter.participantLeft(participant.participantId)
            }
        }

        override fun onStreamsAdded(stage: Stage, participant: ParticipantInfo, streams: MutableList<StageStream>) {
            println("-------------->>>>>>> Streams added: ${streams.joinToString(", ") { it.device.tag }}")
            if (!participant.isLocal) {
                participantAdapter.participantUpdated(participant.participantId) {
                    it.streams.addAll(streams)
                }
            }
        }

        override fun onStreamsRemoved(stage: Stage, participant: ParticipantInfo, streams: MutableList<StageStream>) {
            println("-------------->>>>>>> Streams removed: ${streams.joinToString(", ") { it.device.tag }}")
            if (!participant.isLocal) {
                participantAdapter.participantUpdated(participant.participantId) {
                    it.streams.removeAll(streams)
                }
            }
        }
    }

    private fun createStage(token: String, streams: List<LocalStageStream>): Stage {
        return Stage(application, token, object : Stage.Strategy {
            override fun stageStreamsToPublishForParticipant(
                stage: Stage,
                participantInfo: ParticipantInfo
            ): MutableList<LocalStageStream> = streams.toMutableList()

            override fun shouldPublishFromParticipant(
                stage: Stage,
                participantInfo: ParticipantInfo
            ): Boolean = publishEnabled

            override fun shouldSubscribeToParticipant(
                stage: Stage,
                participantInfo: ParticipantInfo
            ): SubscribeType = SubscribeType.AUDIO_VIDEO
        }).apply {
            addRenderer(StageRendererImpl(participantAdapter, _connectionState))
        }
    }

    fun joinStage(token: String, streams: List<LocalStageStream>, isScreenShare: Boolean = false) {
        if (isScreenShare) {
            handleScreenShareStage(token, streams)
        } else {
            handleMainStage(token, streams)
        }
    }

    private fun handleScreenShareStage(token: String, streams: List<LocalStageStream>) {
        if (ssStage != null) {
            ssStage?.leave()
            ssStage?.release()
            ssStage = null
        }

        try {
            val newStage = createStage(token, streams)
            newStage.join()
            ssStage = newStage
        } catch (e: BroadcastException) {
            Log.e(TAG, "Failed to join screen share stage", e)
            Toast.makeText(application, "Failed to join screen share stage: ${e.localizedMessage}", Toast.LENGTH_LONG).show()
            cleanupScreenShareStage()
        }
    }

    private fun handleMainStage(token: String, streams: List<LocalStageStream>) {
        if (_connectionState.value != Stage.ConnectionState.DISCONNECTED) {
            stage?.leave()
            stage?.release()
            stage = null
        }

        if (token.isEmpty()) {
            Toast.makeText(application, "Empty Token", Toast.LENGTH_SHORT).show()
            return
        }

        try {
            val newStage = createStage(token, streams)
            newStage.join()
            stage = newStage
        } catch (e: BroadcastException) {
            Log.e(TAG, "Failed to join main stage", e)
            Toast.makeText(application, "Failed to join stage: ${e.localizedMessage}", Toast.LENGTH_LONG).show()
            cleanupMainStage()
        }
    }

    fun release() {
        cleanupMainStage()
        cleanupScreenShareStage()
    }

    private fun cleanupMainStage() {
        stage?.leave()
        stage?.release()
        stage = null
    }

    private fun cleanupScreenShareStage() {
        ssStage?.leave()
        ssStage?.release()
        ssStage = null
    }

    fun setPublishEnabled(enabled: Boolean) {
        publishEnabled = enabled
        stage?.refreshStrategy()
        ssStage?.refreshStrategy()
    }

    fun refreshStrategy() {
        stage?.refreshStrategy()
    }

    fun refreshScreenShareStrategy() {
        ssStage?.refreshStrategy()
    }

    fun leaveScreenShareStage() {
        cleanupScreenShareStage()
        participantAdapter.clearScreenShareParticipants()
    }

    companion object {
        private const val TAG = "AmazonIVS"
    }
} 