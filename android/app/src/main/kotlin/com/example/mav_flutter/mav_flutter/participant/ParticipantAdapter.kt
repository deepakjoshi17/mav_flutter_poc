package com.example.mav_flutter.mav_flutter.participant

import android.os.Build
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.annotation.RequiresApi
import androidx.recyclerview.widget.RecyclerView
import com.amazonaws.ivs.broadcast.AudioLocalStageStream
import com.amazonaws.ivs.broadcast.ImageLocalStageStream
import com.amazonaws.ivs.broadcast.LocalStageStream
import com.example.mav_flutter.mav_flutter.R

@RequiresApi(Build.VERSION_CODES.P)
class ParticipantAdapter : RecyclerView.Adapter<ParticipantAdapter.ViewHolder>() {

    val participants = mutableListOf<StageParticipant>()
    private val screenShareParticipantIds = mutableSetOf<String>()

    init {
        setHasStableIds(true)
    }

    fun participantJoined(participant: StageParticipant) {
        //check if the participant is already in the list
        if (participants.any { it.participantId == participant.participantId }) {
            return
        }
        participants.add(participant)
        notifyItemInserted(participants.size - 1)
    }

    fun addScreenShareParticipant(participantId: String) {
        screenShareParticipantIds.add(participantId)
    }

    fun participantLeft(participantId: String) {
        val index = participants.indexOfFirst { it.participantId == participantId }
        if (index != -1) {
            participants.removeAt(index)
            notifyItemRemoved(index)
        }
    }

    fun participantUpdated(participantId: String?, update: (participant: StageParticipant) -> Unit) {
        val index = participants.indexOfFirst { it.participantId == participantId }
        if (index != -1) {
            update(participants[index])
            notifyItemChanged(index, participants[index])
        }
    }

    fun muteAudio(mute: Boolean) {
        (participants[0].streams.first { it is AudioLocalStageStream } as LocalStageStream).muted = mute
        notifyItemChanged(0, participants[0])
    }

    fun muteVideo(mute: Boolean) {
        (participants[0].streams.first { it is ImageLocalStageStream } as LocalStageStream).muted = mute
        notifyItemChanged(0, participants[0])
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val item = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_stage_participant, parent, false) as ParticipantItem
        return ViewHolder(item)
    }

    override fun getItemCount(): Int {
        return participants.size
    }

    override fun getItemId(position: Int): Long =
        participants[position]
            .stableID
            .hashCode()
            .toLong()

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        return holder.participantItem.bind(participants[position])
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int, payloads: MutableList<Any>) {
        val updates = payloads.filterIsInstance<StageParticipant>()
        if (updates.isNotEmpty()) {
            updates.forEach { holder.participantItem.bind(it) }
        } else {
            super.onBindViewHolder(holder, position, payloads)
        }
    }

    fun clearScreenShareParticipants() {
        val screenShareParticipants = participants.filter { participant ->
            screenShareParticipantIds.contains(participant.participantId)
        }
        
        screenShareParticipants.forEach { participant ->
            val index = participants.indexOf(participant)
            if (index != -1) {
                participants.removeAt(index)
                notifyItemRemoved(index)
            }
        }
        screenShareParticipantIds.clear()
    }

    class ViewHolder(val participantItem: ParticipantItem) : RecyclerView.ViewHolder(participantItem)
}