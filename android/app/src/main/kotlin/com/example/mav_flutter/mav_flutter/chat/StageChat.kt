package com.example.mav_flutter.mav_flutter.chat

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.amazonaws.ivs.chat.messaging.ChatRoom
import com.amazonaws.ivs.chat.messaging.ChatRoomListener
import com.amazonaws.ivs.chat.messaging.ChatToken
import com.amazonaws.ivs.chat.messaging.DisconnectReason
import com.amazonaws.ivs.chat.messaging.SendMessageCallback
import com.amazonaws.ivs.chat.messaging.entities.ChatError
import com.amazonaws.ivs.chat.messaging.entities.ChatEvent
import com.amazonaws.ivs.chat.messaging.entities.ChatMessage
import com.amazonaws.ivs.chat.messaging.entities.DeleteMessageEvent
import com.amazonaws.ivs.chat.messaging.entities.DisconnectUserEvent
import com.amazonaws.ivs.chat.messaging.requests.SendMessageRequest
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.launch
import java.text.ParseException
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class StageChat(var sink: EventChannel.EventSink?) {
    var room: ChatRoom? = null

    private fun initialize(chatToken: String) {

        if (room != null) {
            room?.listener = null
            room?.disconnect()
        }
        Log.d("StageChat", "Chat room is destroying...")
//        val token = methodCall.argument<Any>("chatToken") as String?
        val sessionExpiryIso = "2025-03-21T13:52:15.000Z"
        val expiryIso = "2025-03-21T13:27:15.000Z"
        val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.getDefault())

        isoFormat.timeZone = TimeZone.getTimeZone("UTC")
        var sessionExpiryDate: Date?
        var tokenExpiryDate: Date?

        try {
            sessionExpiryDate = sessionExpiryIso?.let { isoFormat.parse(it) }
            tokenExpiryDate = expiryIso?.let { isoFormat.parse(it) }
            val finalTokenExpiryDate = tokenExpiryDate
            val finalSessionExpiryDate = sessionExpiryDate
            room = ChatRoom(
                "us-east-1",
                tokenProvider = { chatTokenCallback ->
                chatTokenCallback.onSuccess(
                    ChatToken(
                        chatToken,
                        finalSessionExpiryDate,
                        finalTokenExpiryDate
                    )
                )
            })
            Log.d(
                "StageChat",
                "Token: $chatToken, Session Expiry: $finalSessionExpiryDate, Token Expiry: $finalTokenExpiryDate"
            )
            Log.d("StageChat", "Chat is ready")

            room?.listener = (object : ChatRoomListener {
                override fun onConnecting(room: ChatRoom) {
                    Log.d("StageChat", "onConnecting")
                }

                override fun onConnected(room: ChatRoom) {
                    Log.d("StageChat", "onConnected")
                    if (this@StageChat.room != null) {
                        CoroutineScope(Dispatchers.IO).launch {
                            receiveMessages()
                            receiveEvents()
                        }
                    }
                }

                override fun onDisconnected(
                    room: ChatRoom,
                    reason: DisconnectReason
                ) {
                    Log.d("StageChat", "onDisconnected")
                }

                override fun onMessageReceived(room: ChatRoom, message: ChatMessage) {
                    Log.d("StageChat ----->", "onMessageReceived, message: " + message.content)
                }

                override fun onEventReceived(room: ChatRoom, event: ChatEvent) {
                    Handler(Looper.getMainLooper()).post {
                        if (sink != null) sink!!.success(event.eventName)
                    }
                    Log.d("StageChat ----->", "onEventReceived 2 - " + event.eventName)
                }

                override fun onMessageDeleted(
                    room: ChatRoom,
                    event: DeleteMessageEvent
                ) {
                    Log.d("StageChat ----->", "onMessageDeleted")
                }

                override fun onUserDisconnected(
                    room: ChatRoom,
                    event: DisconnectUserEvent
                ) {
                    Log.d("StageChat", "onUserDisconnected")
                }
            })

        } catch (e: ParseException) {
            Log.d("StageChat", "this is error " + e.message)
            Log.d("StageChat", "Chat is not ready")
        }
    }

    fun join(chatToken: String, result: MethodChannel.Result) {
        initialize(chatToken)
        room?.connect()
        result.success(null)
    }

    suspend fun receiveMessages() {
        flow {
            room?.let { chatRoom ->
                chatRoom.listener?.let { listener ->
                    while (true) {
                        emit(Unit)
                        kotlinx.coroutines.delay(100)
                    }
                }
            }
        }
        .onStart { Log.d("StageChat", "onStart") }
        .onEach { Log.d("StageChat", "onEach") }
        .collect { Log.d("StageChat", "onCollect") }
    }

    suspend fun receiveEvents() {
        flow {
            room?.let { chatRoom ->
                chatRoom.listener?.let { listener ->
                    while (true) {
                        emit(Unit)
                        kotlinx.coroutines.delay(100)
                    }
                }
            }
        }
        .onStart { Log.d("StageChat", "onStart") }
        .onEach { Log.d("StageChat", "onEach") }
        .collect { Log.d("StageChat", "onCollect") }
    }

    fun leave(methodCall: MethodCall?, result: MethodChannel.Result) {
        if (room == null) {
            result.success("Chat is leaving...")
            return
        }
        room?.listener = null
        room?.disconnect()
        Log.d("StageChat", "Chat leave room is destroying...")
        result.success("Chat is leaving...")
    }

    fun sendMessage(chatMessageRequest: ChatMessageRequest) {
        println("Send message $chatMessageRequest")
        val attributes: Map<String, String> = mapOf(
            "message_type" to chatMessageRequest.attributes.messageType,
        )

        room?.sendMessage(SendMessageRequest(chatMessageRequest.content, attributes), object : SendMessageCallback {
            override fun onConfirmed(request: SendMessageRequest, response: ChatMessage) {
                println("Message sent: ${request.requestId} ${response.content}")
            }

            override fun onRejected(request: SendMessageRequest, error: ChatError) {
                println("Message send rejected: ${request.requestId} ${error.errorMessage}")
//                _onError.trySend(NetworkError.MessageSendFailed(error.errorMessage, error.errorCode))
            }
        })
    }
}