package com.example.mav_flutter.mav_flutter.vm

import android.os.Build
import androidx.annotation.RequiresApi
import com.amazonaws.ivs.broadcast.LocalStageStream
import com.amazonaws.ivs.broadcast.ParticipantInfo
import com.amazonaws.ivs.broadcast.Stage
import com.amazonaws.ivs.broadcast.Stage.SubscribeType

@RequiresApi(Build.VERSION_CODES.P)
class StageStrategyImpl(private var streams: List<LocalStageStream>, private var publishEnabled: Boolean): Stage.Strategy {
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
}