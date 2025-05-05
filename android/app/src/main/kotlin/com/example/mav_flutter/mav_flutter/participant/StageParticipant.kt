package com.example.mav_flutter.mav_flutter.participant

import android.os.Build
import androidx.annotation.RequiresApi
import com.amazonaws.ivs.broadcast.Stage
import com.amazonaws.ivs.broadcast.StageStream

class StageParticipant(val isLocal: Boolean, var participantId: String?, val attributes: Map<String, String>? = null) {

    @RequiresApi(Build.VERSION_CODES.P)
    var publishState = Stage.PublishState.NOT_PUBLISHED
    @RequiresApi(Build.VERSION_CODES.P)
    var subscribeState = Stage.SubscribeState.NOT_SUBSCRIBED
    var streams = mutableListOf<StageStream>()

    val stableID: String
        get() {
            return if (isLocal) {
                "LocalUser"
            } else {
                participantId ?: "UnknownParticipant"
            }
        }
}