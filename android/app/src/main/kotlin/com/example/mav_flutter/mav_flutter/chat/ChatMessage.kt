package com.example.mav_flutter.mav_flutter.chat
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.Transient
import java.util.*

const val EVENT_STICKER = "STICKER"
const val EVENT_MESSAGE = "MESSAGE"
const val MESSAGE_TIMEOUT = 20 * 1000L

@Serializable
data class ChatMessageRequest(
    @SerialName("action") val action: String = "SEND_MESSAGE",
    @SerialName("content") val content: String = "",
    @SerialName("attributes") val attributes: MessageAttributes
)

@Serializable
data class ChatMessageResponse(
    val type: String = EVENT_MESSAGE,
    val id: String = "",
    val requestId: String = "",
    val attributes: MessageAttributes? = null,
    var content: String = "",
    var sender: Sender? = null,
    @Transient val timeStamp: Long = Date().time,
    @Transient var viewType: MessageViewType =
        if (attributes?.messageType == EVENT_STICKER) MessageViewType.STICKER else MessageViewType.MESSAGE
) {
    val isExpired get() = Date().time - timeStamp > MESSAGE_TIMEOUT
    /*val imageResource
        get() = STICKERS.find { it.resource == attributes?.stickerSource }?.resource ?: STICKERS.first().resource*/

    fun setNewViewType(type: MessageViewType) {
        viewType = type
    }
}

@Serializable
@SerialName("Attributes")
data class MessageAttributes(
    @SerialName("message_type") val messageType: String = "",
)

@Serializable
data class Sender(
    var id: String? = null,
    var username: String,
    val avatar: String
)

enum class MessageViewType(val index: Int) {
    MESSAGE(0),
    STICKER(1),
    GREEN(2),
    RED(3)
}