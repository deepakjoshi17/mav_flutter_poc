package com.example.mav_flutter.mav_flutter.participant

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.util.AttributeSet
import android.widget.FrameLayout
import android.widget.TextView
import androidx.annotation.RequiresApi
import androidx.cardview.widget.CardView
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.text.toUpperCase
import com.amazonaws.ivs.broadcast.AudioDevice
import com.amazonaws.ivs.broadcast.BroadcastConfiguration
import com.amazonaws.ivs.broadcast.ImageDevice
import com.example.mav_flutter.mav_flutter.R
import java.util.Locale
import kotlin.math.roundToInt
import androidx.core.graphics.toColorInt
import com.amazonaws.ivs.broadcast.StageStream
import kotlin.math.absoluteValue

@RequiresApi(Build.VERSION_CODES.P)
class ParticipantItem @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
    defStyleRes: Int = 0,
) : FrameLayout(context, attrs, defStyleAttr, defStyleRes) {

    private lateinit var previewContainer: FrameLayout
    private lateinit var placeholderView: android.view.View
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
    private var currentAudioLevel: Int = -100  // Track current audio level

    private val SPEAKING_THRESHOLD = -60  // dB threshold for speaking
    private val BORDER_WIDTH = 10  // Border width in pixels
    private val SPEAKING_BORDER_COLOR = "#F15D22"  // Blue color for speaking border
    private val CORNER_RADIUS = 34f  // Corner radius in pixels

    private var avatarBgColorsHex = listOf(
        "#F12D8B",
        "#FAB82B",
        "#F15D22",
        "#0079B5",
        "#86DB99",
        "#9795F0",
        "#6034F2",
        "#09CC91"
    )

    override fun onFinishInflate() {
        super.onFinishInflate()
        previewContainer = findViewById(R.id.participant_preview_container)
        // Add initial border setup
        previewContainer.setBackgroundResource(android.R.color.transparent)
        previewContainer.setPadding(BORDER_WIDTH, BORDER_WIDTH, BORDER_WIDTH, BORDER_WIDTH)
        
        // Create placeholder view for border effect
        placeholderView = android.view.View(context).apply {
            setBackgroundColor(Color(0xFFF2EFED).toArgb())
            clipToOutline = true
            outlineProvider = object : android.view.ViewOutlineProvider() {
                override fun getOutline(view: android.view.View, outline: android.graphics.Outline) {
                    outline.setRoundRect(0, 0, view.width, view.height, CORNER_RADIUS)
                }
            }
        }
        previewContainer.addView(placeholderView, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))
        
        // Set corner radius for the container
        previewContainer.clipToOutline = true
        previewContainer.outlineProvider = object : android.view.ViewOutlineProvider() {
            override fun getOutline(view: android.view.View, outline: android.graphics.Outline) {
                outline.setRoundRect(0, 0, view.width, view.height, CORNER_RADIUS)
            }
        }
        textViewParticipantId = findViewById(R.id.participant_participant_id)
        textViewPublish = findViewById(R.id.participant_publishing)
        textViewSubscribe = findViewById(R.id.participant_subscribed)
        textViewVideoMuted = findViewById(R.id.participant_video_muted)
        textViewAudioMuted = findViewById(R.id.participant_audio_muted)
        textViewAudioLevel = findViewById(R.id.participant_audio_level)
        avatarInitial = findViewById(R.id.avatar_initial)
        avatarContainer = findViewById(R.id.avatar_container)

    }

    private fun updateSpeakingBorder(isSpeaking: Boolean, participant: StageParticipant, audioStream: StageStream?) {
        val shouldShowBorder = isSpeaking && 
            participant.isLocal && 
            audioStream != null && 
            !audioStream.muted

        if (shouldShowBorder) {
            previewContainer.setBackgroundColor(SPEAKING_BORDER_COLOR.toColorInt())
            placeholderView.setBackgroundColor(Color(0xFFF2EFED).toArgb())
        } else {
            previewContainer.setBackgroundColor(Color.Transparent.toArgb())
            placeholderView.setBackgroundColor(Color(0xFFF2EFED).toArgb())
        }
    }

    @SuppressLint("SetTextI18n")
    fun bind(participant: StageParticipant, isSpotlighted: Boolean = false) {
        val participantId = if (participant.isLocal) {
            "You (${participant.participantId ?: "Disconnected"})"
        } else {
            participant.participantId
        }

        var name = participant.attributes?.get("name")
        //split name by space and get first letter of each word
        name = name?.split(" ")?.joinToString("") { it.substring(0, 1) }
        avatarInitial.text = name?.uppercase(Locale.getDefault()) ?: "NA"

        textViewParticipantId.text = participantId
        textViewPublish.text = participant.publishState.name
        textViewSubscribe.text = participant.subscribeState.name

        val newImageStream = participant
            .streams
            .firstOrNull { it.device is ImageDevice }
        textViewVideoMuted.text = if (newImageStream != null) {
            if (newImageStream.muted) "Video muted" else "Video not muted"
        } else {
            "No video stream"
        }

        if (newImageStream == null) {
            val colorIndex = participantId.hashCode().absoluteValue % avatarBgColorsHex.size
            avatarContainer.setCardBackgroundColor(avatarBgColorsHex[colorIndex].toColorInt())
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
            // If the device has changed, remove all subviews except placeholder
            previewContainer.removeAllViews()
            previewContainer.addView(placeholderView, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            ))
            (newImageStream?.device as? ImageDevice)?.let {
                val preview = it.getPreviewView(BroadcastConfiguration.AspectMode.FIT)
                // Set corner radius for the preview
                preview.clipToOutline = true
                preview.outlineProvider = object : android.view.ViewOutlineProvider() {
                    override fun getOutline(view: android.view.View, outline: android.graphics.Outline) {
                        outline.setRoundRect(0, 0, view.width, view.height, CORNER_RADIUS)
                    }
                }
                previewContainer.addView(preview)
                preview.layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            }
        }
        imageDeviceUrn = newImageStream?.device?.descriptor?.urn

        if(newImageStream == null || newImageStream.muted) {
            // Remove all views except placeholder
            previewContainer.removeAllViews()
            previewContainer.addView(placeholderView, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            ))
            imageDeviceUrn = ""
            avatarContainer.visibility = VISIBLE
        } else {
            avatarContainer.visibility = INVISIBLE
        }

        if (newAudioStream?.device?.descriptor?.urn != audioDeviceUrn) {
            (newAudioStream?.device as? AudioDevice)?.let {
                it.setStatsCallback { _, rms ->
                    currentAudioLevel = rms.roundToInt()
                    textViewAudioLevel.text = "Audio Level: $currentAudioLevel dB"
                    updateSpeakingBorder(currentAudioLevel > SPEAKING_THRESHOLD, participant, newAudioStream)
                }
            }
        }
        audioDeviceUrn = newAudioStream?.device?.descriptor?.urn

        // Update border state based on current audio level
        updateSpeakingBorder(currentAudioLevel > SPEAKING_THRESHOLD, participant, newAudioStream)

        if (isSpotlighted) {
            this.setBackgroundResource(android.R.color.holo_blue_dark)
        } else {
            this.setBackgroundResource(0)
        }
    }

}