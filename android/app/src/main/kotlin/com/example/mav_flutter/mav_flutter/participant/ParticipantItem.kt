package com.example.mav_flutter.mav_flutter.participant

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.util.AttributeSet
import android.widget.FrameLayout
import android.widget.TextView
import androidx.annotation.RequiresApi
import androidx.cardview.widget.CardView
import com.amazonaws.ivs.broadcast.AudioDevice
import com.amazonaws.ivs.broadcast.BroadcastConfiguration
import com.amazonaws.ivs.broadcast.ImageDevice
import com.example.mav_flutter.mav_flutter.R
import kotlin.math.roundToInt

@RequiresApi(Build.VERSION_CODES.P)
class ParticipantItem @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
    defStyleRes: Int = 0,
) : FrameLayout(context, attrs, defStyleAttr, defStyleRes) {

    private lateinit var previewContainer: FrameLayout
    private lateinit var textViewParticipantId: TextView
    private lateinit var textViewPublish: TextView
    private lateinit var textViewSubscribe: TextView
    private lateinit var textViewVideoMuted: TextView
    private lateinit var textViewAudioMuted: TextView
    private lateinit var textViewAudioLevel: TextView
    private lateinit var avatarInitial: TextView
    private lateinit var avatarContainer: CardView

    private var imageDeviceUrn: String? = null
    private var audioDeviceUrn: String? = null

    override fun onFinishInflate() {
        super.onFinishInflate()
        previewContainer = findViewById(R.id.participant_preview_container)
        textViewParticipantId = findViewById(R.id.participant_participant_id)
        textViewPublish = findViewById(R.id.participant_publishing)
        textViewSubscribe = findViewById(R.id.participant_subscribed)
        textViewVideoMuted = findViewById(R.id.participant_video_muted)
        textViewAudioMuted = findViewById(R.id.participant_audio_muted)
        textViewAudioLevel = findViewById(R.id.participant_audio_level)
        avatarInitial = findViewById(R.id.avatar_initial)
        avatarContainer = findViewById(R.id.avatar_container)

    }

    @SuppressLint("SetTextI18n")
    fun bind(participant: StageParticipant) {
        val participantId = if (participant.isLocal) {
            "You (${participant.participantId ?: "Disconnected"})"
        } else {
            participant.participantId
        }
        textViewParticipantId.text = participantId
        textViewPublish.text = participant.publishState.name
        textViewSubscribe.text = participant.subscribeState.name
        avatarInitial.text = "DJ"

        val newImageStream = participant
            .streams
            .firstOrNull { it.device is ImageDevice }
        textViewVideoMuted.text = if (newImageStream != null) {
            if (newImageStream.muted) "Video muted" else "Video not muted"
        } else {
            "No video stream"
        }

        val newAudioStream = participant
            .streams
            .firstOrNull { it.device is AudioDevice }
        textViewAudioMuted.text = if (newAudioStream != null) {
            if (newAudioStream.muted) "Audio muted" else "Audio not muted"
        } else {
            "No audio stream"
        }

        if (newImageStream?.device?.descriptor?.urn != imageDeviceUrn) {
            // If the device has changed, remove all subviews from the preview container
            previewContainer.removeAllViews()
            (newImageStream?.device as? ImageDevice)?.let {
                val preview = it.getPreviewView(BroadcastConfiguration.AspectMode.FIT)
                previewContainer.addView(preview)
                preview.layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            }
        }
        imageDeviceUrn = newImageStream?.device?.descriptor?.urn

        if(newImageStream == null || newImageStream.muted) {
            previewContainer.removeAllViews()
            imageDeviceUrn = ""
            avatarContainer.visibility = VISIBLE
        } else {
            avatarContainer.visibility = INVISIBLE
        }

        if (newAudioStream?.device?.descriptor?.urn != audioDeviceUrn) {
            (newAudioStream?.device as? AudioDevice)?.let {
                it.setStatsCallback { _, rms ->
                    textViewAudioLevel.text = "Audio Level: ${rms.roundToInt()} dB"
                }
            }
        }
        audioDeviceUrn = newAudioStream?.device?.descriptor?.urn
    }

}