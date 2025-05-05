package com.example.mav_flutter.mav_flutter

import android.Manifest
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import android.os.PersistableBundle
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.example.mav_flutter.mav_flutter.chat.ChatMessageRequest
import com.example.mav_flutter.mav_flutter.chat.MessageAttributes
import com.example.mav_flutter.mav_flutter.chat.StageChat
import com.example.mav_flutter.mav_flutter.platform.NativeViewFactory
import com.example.mav_flutter.mav_flutter.screen_share.MyMediaProjectionService
import com.example.mav_flutter.mav_flutter.screen_share.MyMediaProjectionService.Companion.EXTRA_DATA
import com.example.mav_flutter.mav_flutter.screen_share.MyMediaProjectionService.Companion.EXTRA_RESULT_CODE
import com.example.mav_flutter.mav_flutter.vm.NativeViewModel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel


@RequiresApi(Build.VERSION_CODES.P)
class MainActivity: FlutterFragmentActivity() {

    private val CHANNEL = "mav_flutter/controls"
    private lateinit var viewModel: NativeViewModel
    private var isReceiverRegistered = false

    private var displayToken = ""

    private val callback = fun(intent: Intent) {
        println("*****Callback called")
        viewModel.startScreenShare(displayToken, intent)
    }

    private val receiver: MyBroadcastReceiver = MyBroadcastReceiver(callback)

    class MyBroadcastReceiver(private val callback: (Intent) -> Unit) : BroadcastReceiver() {

        override fun onReceive(context: Context, intent: Intent) {
            if (MyMediaProjectionService.ACTION_START_MEDIA_PROJECTION == intent.action) {
                // Handle the message from the service
                val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, 0)
                val data = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(EXTRA_DATA, Intent::class.java)
                } else {
                    intent.getParcelableExtra(EXTRA_DATA)
                }
                if (resultCode != 0 && data != null) {

                    val mpIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(EXTRA_DATA, Intent::class.java)
                    } else {
                        intent.getParcelableExtra(EXTRA_DATA)
                    }
                    if(mpIntent != null) callback(mpIntent)
                    else println("*****Intent is null")
                }
            }
        }
    }

    private val stageChat: StageChat = StageChat(object: EventSink {
        override fun success(event: Any?) {
            println("*****Event: $event")
        }

        override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
            println("*****Error: $errorCode, $errorMessage, $errorDetails")
        }

        override fun endOfStream() {
            println("*****End of stream")
        }
    })

    override fun onStart() {
        super.onStart()
        viewModel = viewModels<NativeViewModel>().value
        checkPermissions()
        if (!isReceiverRegistered) {
            val filter = IntentFilter(MyMediaProjectionService.ACTION_START_MEDIA_PROJECTION)
            filter.addCategory(Intent.CATEGORY_DEFAULT)
            println("REGISTERING RECEIVER <T")
            LocalBroadcastManager.getInstance(this).registerReceiver(receiver, filter)
            isReceiverRegistered = true
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory("native_ivs_view_android", NativeViewFactory(this))

        // Add event channel for chat messages
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "mav_flutter/chat_messages").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventSink) {
                    println("*****onListen called")
                    stageChat.sink = events
                }

                override fun onCancel(arguments: Any?) {
                    stageChat.sink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler(fun(
            call: MethodCall,
            result: MethodChannel.Result
        ) {
            println("*****Method call: ${call.method}")
            when (call.method) {
                "leaveStage" -> {
                    viewModel.leaveStage()
                    result.success(null)
                }
                "joinStage" -> {
                    val args = call.arguments as Map<*, *>
                    val token = args["videoToken"] as String
                    val chatToken = args["chatToken"] as String
                    val audioMuted = args["audioMuted"] as Boolean
                    val videoMuted = args["videoMuted"] as Boolean

                    viewModel.joinStage(token)
                    stageChat.join(chatToken, result)
                }
                "toggleMic" -> {
                    viewModel.toggleMic()
                    result.success(null)
                }
                "toggleCamera" -> {
                    viewModel.toggleCamera()
                    result.success(null)
                }
                "sendMessage" -> {
                    stageChat.sendMessage(ChatMessageRequest(
                        content = call.argument("message") ?: "",
                        attributes = MessageAttributes(
                            call.argument("messageType") ?: "chatEvent"
                        )
                    ))
                    result.success(null)
                }
                "startScreenShare" -> {

                    displayToken = call.argument("displayToken") ?: ""
                    requestScreenCapturePermission()
                    result.success("Screen Share Started")
                }
                "stopScreenShare" -> {
                    viewModel.stopScreenShare()
                    result.success("Screen Share Stopped")
                }

                else -> result.notImplemented()
            }
        })
    }

    private val mediaProjectionManager: MediaProjectionManager by lazy {
        applicationContext.getSystemService("media_projection") as MediaProjectionManager
    }

    private fun requestScreenCapturePermission() {
        val captureIntent = mediaProjectionManager.createScreenCaptureIntent()
        screenCaptureIntentLauncher.launch(captureIntent)
    }

    private val screenCaptureIntentLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {

            val data: Intent? = result.data
            val serviceIntent = Intent(this, MyMediaProjectionService::class.java).apply {
                action = MyMediaProjectionService.ACTION_START_MEDIA_PROJECTION
                putExtra(EXTRA_RESULT_CODE, result.resultCode)
                putExtra(EXTRA_DATA, data)
            }
            startForegroundService(serviceIntent)
        } else {
            // Handle permission denied
            println("*****Permission denied")
        }
    }

    override fun onResume() {
        super.onResume()

        println("*****onResume called")
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 101 && permissions.contains(Manifest.permission.CAMERA) && permissions.contains(Manifest.permission.RECORD_AUDIO)) {
            viewModel.permissionGranted()
        }
    }

    private val permissions = listOf(
        Manifest.permission.CAMERA,
        Manifest.permission.RECORD_AUDIO,
    )

    private fun checkPermissions() {
        when {
            this.hasPermissions(permissions) -> {
                viewModel.permissionGranted()
            }
            else -> requestPermissions(permissions.toTypedArray(), 101)
        }
    }

    private fun Context.hasPermissions(permissions: List<String>): Boolean {
        return permissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        viewModel.onCleared()
    }
}
