package com.example.mav_flutter.mav_flutter

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.util.Log
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.amazonaws.ivs.broadcast.*
import com.example.mav_flutter.mav_flutter.chat.ChatMessageRequest
import com.example.mav_flutter.mav_flutter.chat.MessageAttributes
import com.example.mav_flutter.mav_flutter.chat.StageChat
import com.example.mav_flutter.mav_flutter.platform.NativeViewFactory
import com.example.mav_flutter.mav_flutter.screen_share.MyMediaProjectionService
import com.example.mav_flutter.mav_flutter.screen_share.MyMediaProjectionService.Companion.EXTRA_DATA
import com.example.mav_flutter.mav_flutter.screen_share.MyMediaProjectionService.Companion.EXTRA_RESULT_CODE
import com.example.mav_flutter.mav_flutter.vm.NativeViewModel
import com.example.mav_flutter.mav_flutter.vm.ScreenCaptureBroadcastReceiver
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.*

@RequiresApi(Build.VERSION_CODES.P)
class MainActivity: FlutterFragmentActivity() {
    private val TAG = "MainActivity"
    private val CHANNEL = "mav_flutter/controls"
    private lateinit var viewModel: NativeViewModel
    private var isReceiverRegistered = false
    private lateinit var deviceDiscovery: DeviceDiscovery
    private lateinit var audioManager: AudioManager

    private var displayToken = ""

    private val callback = { intent: Intent ->
        println("*****Callback called from the broadcast receiver")
        viewModel.startScreenShare(displayToken, intent)
    }

    private val receiver: ScreenCaptureBroadcastReceiver = ScreenCaptureBroadcastReceiver(callback)

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
        deviceDiscovery = DeviceDiscovery(applicationContext)
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
            println("*****Method call: ${call.method}")
            when (call.method) {
                "initLocalParticipant" -> {
                    viewModel.initLocalParticipant(call.arguments as Map<String, String>)
                    result.success(null)
                }
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
                            call.argument("messageType") ?: "chatEvent",
                            call.argument("senderId") ?: "NA"
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
                "getAudioDevices" -> {
                    try {
                        val devices = getAudioDevices()
                        result.success(devices)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error getting audio devices", e)
                        result.error("DEVICE_ERROR", "Failed to get audio devices", e.message)
                    }
                }
                "getVideoDevices" -> {
                    try {
                        val devices = getVideoDevices()
                        result.success(devices)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error getting video devices", e)
                        result.error("DEVICE_ERROR", "Failed to get video devices", e.message)
                    }
                }
                "switchAudioDevice" -> {
                    try {
                        val deviceId = call.argument<String>("deviceId")
                        if (deviceId != null) {
                            switchAudioDevice(deviceId)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGUMENT", "Device ID is required", null)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error switching audio device", e)
                        result.error("DEVICE_ERROR", "Failed to switch audio device", e.message)
                    }
                }
                "switchVideoDevice" -> {
                    try {
                        val deviceId = call.argument<String>("deviceId")
                        if (deviceId != null) {
                            switchVideoDevice(deviceId)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGUMENT", "Device ID is required", null)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error switching video device", e)
                        result.error("DEVICE_ERROR", "Failed to switch video device", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }
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

    private fun getAudioDevices(): List<String> {
        val devices = mutableListOf<String>()
        
        // Get built-in microphone
        devices.add("Built-in Microphone")
        
        // Get connected audio devices
        val audioDevices = audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS)
        for (device in audioDevices) {
            when (device.type) {
                AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
                AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
                AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
                AudioDeviceInfo.TYPE_WIRED_HEADSET,
                AudioDeviceInfo.TYPE_USB_DEVICE -> {
                    val deviceName = device.productName.toString()
                    if (deviceName.isNotEmpty() && !devices.contains(deviceName)) {
                        devices.add(deviceName)
                    }
                }
            }
        }
        
        return devices
    }

    private fun getVideoDevices(): List<Map<String, String>> {
        val devices = mutableListOf<Map<String, String>>()
        val cameras = deviceDiscovery.listLocalDevices()
            .filter { it.descriptor.type == Device.Descriptor.DeviceType.CAMERA }

        val addedPositions = mutableSetOf<Device.Descriptor.Position>()
        for (camera in cameras) {
            val position = camera.descriptor.position
            if (addedPositions.contains(position)) continue // Skip duplicates by position

            val label = when (position) {
                Device.Descriptor.Position.FRONT -> "Front Camera"
                Device.Descriptor.Position.BACK -> "Back Camera"
                else -> camera.descriptor.friendlyName
            }
            val urn = camera.descriptor.urn
            if (label.isNotEmpty()) {
                devices.add(mapOf("label" to label, "id" to urn))
                addedPositions.add(position)
            }
        }
        return devices;
    }

    private fun switchAudioDevice(deviceId: String) {
        when (deviceId) {
            "Built-in Microphone" -> {
                // Switch to built-in microphone
                audioManager.mode = AudioManager.MODE_NORMAL
                audioManager.isSpeakerphoneOn = false
            }
            else -> {
                // For other devices, try to switch based on device type
                val audioDevices = audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS)
                for (device in audioDevices) {
                    if (device.productName.toString() == deviceId) {
                        when (device.type) {
                            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
                            AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> {
                                audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                                audioManager.isBluetoothScoOn = true
                            }
                            AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
                            AudioDeviceInfo.TYPE_WIRED_HEADSET -> {
                                audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                                audioManager.isSpeakerphoneOn = false
                            }
                            AudioDeviceInfo.TYPE_USB_DEVICE -> {
                                audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                                audioManager.isSpeakerphoneOn = false
                            }
                        }
                        break
                    }
                }
            }
        }
        
        // Notify the IVS stage about the device change
        viewModel.updateAudioDevice(deviceId)
    }

    private fun switchVideoDevice(deviceId: String) {
        val cameras = deviceDiscovery.listLocalDevices()
            .filter { it.descriptor.type == Device.Descriptor.DeviceType.CAMERA }
        val camera = cameras.find { it.descriptor.urn == deviceId }
        if (camera != null) {
            viewModel.updateVideoDeviceByDescriptor(camera)
        }
    }
}
