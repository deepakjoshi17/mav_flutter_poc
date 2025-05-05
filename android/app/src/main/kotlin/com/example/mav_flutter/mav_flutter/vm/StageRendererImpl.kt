package com.example.mav_flutter.mav_flutter.vm

import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import com.amazonaws.ivs.broadcast.*
import com.example.mav_flutter.mav_flutter.participant.ParticipantAdapter
import com.example.mav_flutter.mav_flutter.participant.StageParticipant
import kotlinx.coroutines.flow.MutableStateFlow

@RequiresApi(Build.VERSION_CODES.P)
class StageRendererImpl(
    private val participantAdapter: ParticipantAdapter,
    private val connectionState: MutableStateFlow<Stage.ConnectionState>
) : StageRenderer {
    override fun onError(exception: BroadcastException) {
        Log.e(TAG, "Stage error: ${exception.localizedMessage}")
    }

    override fun onConnectionStateChanged(
        stage: Stage,
        connectionState: Stage.ConnectionState,
        exception: BroadcastException?
    ) {
        println("-------------->>>>>>> Connection state changed: ${connectionState.name}")
        this.connectionState.value = connectionState
    }

    override fun onParticipantJoined(stage: Stage, participantInfo: ParticipantInfo) {
        println("-------------->>>>>>> Participant joined: ${participantInfo.participantId}")
        if (participantInfo.isLocal) {
            participantAdapter.participantUpdated(null) {
                it.participantId = participantInfo.participantId
            }
        } else {

            println("-------------->>>>>>> Remote Participant joined: ${participantInfo.attributes}")
            participantAdapter.participantJoined(
                StageParticipant(participantInfo.isLocal, participantInfo.participantId)
            )
        }
    }

    override fun onParticipantLeft(stage: Stage, participantInfo: ParticipantInfo) {
        println("-------------->>>>>>> Participant left: ${participantInfo.participantId}")
        if (participantInfo.isLocal) {
            participantAdapter.participantUpdated(participantInfo.participantId) {
                it.participantId = null
            }
        } else {
            participantAdapter.participantLeft(participantInfo.participantId)
        }
    }

    override fun onParticipantPublishStateChanged(
        stage: Stage,
        participantInfo: ParticipantInfo,
        publishState: Stage.PublishState
    ) {
        println("-------------->>>>>>> Publish state changed: ${publishState.name}")
        participantAdapter.participantUpdated(participantInfo.participantId) {
            it.publishState = publishState
        }
    }

    override fun onParticipantSubscribeStateChanged(
        stage: Stage,
        participantInfo: ParticipantInfo,
        subscribeState: Stage.SubscribeState
    ) {
        println("-------------->>>>>>> Subscribe state changed: ${subscribeState.name}")
        participantAdapter.participantUpdated(participantInfo.participantId) {
            it.subscribeState = subscribeState
        }
    }

    override fun onStreamsAdded(stage: Stage, participantInfo: ParticipantInfo, streams: MutableList<StageStream>) {
        if (!participantInfo.isLocal) {
            participantAdapter.participantUpdated(participantInfo.participantId) {
                it.streams.addAll(streams)
            }
        }
    }

    override fun onStreamsRemoved(stage: Stage, participantInfo: ParticipantInfo, streams: MutableList<StageStream>) {
        if (!participantInfo.isLocal) {
            participantAdapter.participantUpdated(participantInfo.participantId) {
                it.streams.removeAll(streams)
            }
        }
    }

    override fun onStreamsMutedChanged(
        stage: Stage,
        participantInfo: ParticipantInfo,
        streams: MutableList<StageStream>
    ) {
        if (!participantInfo.isLocal) {
            participantAdapter.participantUpdated(participantInfo.participantId) {}
        }
    }

    companion object {
        private const val TAG = "AmazonIVS"
    }
} 