import 'dart:developer';

import 'package:flutter/services.dart';
import '../models/aws_ivs_create_participant_token.dart';

const onErrorMethodName = "onError";
const onConnectionStateChangedMethodName = "onConnectionStateChanged";
const onLocalAudioStateChangedMethodName = "onLocalAudioStateChanged";
const onLocalVideoStateChangedMethodName = "onLocalVideoStateChanged";
const onBroadcastStateChangedMethodName = "onBroadcastStateChanged";
const onMessageReceivedMethodName = "onMessageReceived";

class FlutterAwsIvsController {
  late MethodChannel _channel;
  FlutterAwsIvsControllerListener? _listener;
  AwsIvsCreateParticipantToken? awsIvsCreateParticipantToken;

  setListener(FlutterAwsIvsControllerListener listener) {
    _listener = listener;
  }

  FlutterAwsIvsController.init(int id) {
    _channel = MethodChannel('flutter_aws_ivs_$id');
    _channel.setMethodCallHandler(handleMethodCall);
  }

  Future<dynamic> handleMethodCall(MethodCall methodCall) async {
    // print(methodCall.method);
    switch (methodCall.method) {
      case onErrorMethodName:
        _listener?.onError();
        return;
      case onConnectionStateChangedMethodName:
        _listener?.onConnectionStateChanged(methodCall.arguments);
        return;
      case onLocalAudioStateChangedMethodName:
        _listener?.onLocalAudioStateChanged(methodCall.arguments);
        return;
      case onLocalVideoStateChangedMethodName:
        _listener?.onLocalVideoStateChanged(methodCall.arguments);
        return;
      case onBroadcastStateChangedMethodName:
        _listener?.onBroadcastStateChanged(methodCall.arguments);
        return;
      case onMessageReceivedMethodName:   // Add this case
        _listener?.onMessageReceived(methodCall.arguments);
        return;
    }
    return;
  }

  Future<void> joinStage(String participantToken) async {
    return _channel.invokeMethod('joinStage', participantToken);
  }

  Future<void> joinChatRoom(String chatRoomToken, String region) async {
    return _channel.invokeMethod('joinChatRoom', {
      "token": chatRoomToken,
      "region": region,
    });
  }

  Future<void> leaveChatRoom() async {
    return _channel.invokeMethod('leaveChatRoom');
  }

  Future<void> sendChatMessage(String message) async {
    return _channel.invokeMethod('sendMessage', message);
  }

  Future<void> leaveStage() async {
    return _channel.invokeMethod('leaveStage');
  }

  Future<void> initView() async {
    return _channel.invokeMethod('initView');
  }

  Future<bool?> toggleLocalAudioMute() async {
    return _channel.invokeMethod<bool>('toggleLocalAudioMute');
  }

  Future<bool?> toggleLocalVideoMute() async {
    return _channel.invokeMethod<bool>('toggleLocalVideoMute');
  }

  Future<void> startScreenShare(Map<String, dynamic> args) async {
    return _channel.invokeMethod('startScreenShare', args);
  }

  Future<void> stopScreenShare() async {
    return _channel.invokeMethod('stopScreenShare');
  }
}

abstract class FlutterAwsIvsControllerListener {
  onError();
  onConnectionStateChanged(int state);
  onLocalAudioStateChanged(bool isMuted);
  onLocalVideoStateChanged(bool isMuted);
  onBroadcastStateChanged(bool isBroadcasting);
  onMessageReceived(Map<dynamic, dynamic> message);
}


class IVSIOSControllerListener implements FlutterAwsIvsControllerListener {
  @override
  onBroadcastStateChanged(bool isBroadcasting) {
    log("IVSIOSControllerListener : Broadcast state changed: $isBroadcasting");
  }

  @override
  onConnectionStateChanged(int state) {
    log("IVSIOSControllerListener: Connection state changed: $state");
  }

  @override
  onError() {
    log("IVSIOSControllerListener: Error occurred");
  }

  @override
  onLocalAudioStateChanged(bool isMuted) {
    log("IVSIOSControllerListener: Local audio state changed: $isMuted");
  }

  @override
  onLocalVideoStateChanged(bool isMuted) {
    log("IVSIOSControllerListener: Local video state changed: $isMuted");
  }

  @override
  onMessageReceived(Map message) {
    log("IVSIOSControllerListener: Message received: $message");
  }

}