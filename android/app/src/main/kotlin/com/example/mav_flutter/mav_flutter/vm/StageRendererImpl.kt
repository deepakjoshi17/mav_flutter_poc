package com.example.mav_flutter.mav_flutter.vm

import android.annotation.SuppressLint
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import com.amazonaws.ivs.broadcast.*
import com.example.mav_flutter.mav_flutter.participant.ParticipantAdapter
import com.example.mav_flutter.mav_flutter.participant.StageParticipant
import com.example.mav_flutter.mav_flutter.vm.StageManager.Companion
import kotlinx.coroutines.flow.MutableStateFlow

@RequiresApi(Build.VERSION_CODES.P)
class StageRendererImpl(
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

    @SuppressLint("NotifyDataSetChanged")
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
        Log.e(TAG, "-------------->>>>>>> Stage error: ${exception.localizedMessage}")
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

    companion object {
        private const val TAG = "StageRender-IVSAndroid"
    }
}