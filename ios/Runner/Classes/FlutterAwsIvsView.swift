import Foundation
import Flutter
import UIKit
import AmazonIVSBroadcast

class FlutterAwsIvsView: NSObject, FlutterPlatformView {
    private var _awsBoardcastView: AWSBroadcastView
    private var _methodChannel: FlutterMethodChannel
    private var _ivsChatManager: IVSChatManager
    
    func view() -> UIView {
        return _awsBoardcastView
    }
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        var layout = ParticipantCollectionViewLayout()
        _awsBoardcastView = AWSBroadcastView.init(frame: frame, collectionViewLayout: layout)
        
        _methodChannel = FlutterMethodChannel(name: "flutter_aws_ivs_\(viewId)", binaryMessenger: messenger)
        
        _ivsChatManager = IVSChatManager()

        super.init()
        // iOS views can be created here
        _awsBoardcastView.stateProtocol = self
        _methodChannel.setMethodCallHandler(onMethodCall)
    }


    func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        switch(call.method){
        case "initView":
            initView(call:call, result:result)
            
        case "joinStage":
            joinStage(call:call, result:result)
            
        case "leaveStage":
            leaveStage(call:call, result:result)
            
        case "toggleLocalVideoMute":
            toggleLocalVideoMute(call: call, result: result)
            
        case "toggleLocalAudioMute":
            toggleLocalAudioMute(call: call, result: result)

        case "sendMessage":
            sendChatMessage(call: call, result: result)
            
        case "joinChatRoom":
            joinChatRoom(call: call, result: result)
        
        case "leaveChatRoom":
            leaveChatRoom(call: call, result: result)
        
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func joinChatRoom(call: FlutterMethodCall, result: FlutterResult){
        let req = call.arguments as! [String:Any]
        let token = req["token"] as! String
        let region = req["region"] as! String
        _ivsChatManager.initializeManager(region: region)
        _ivsChatManager.updateToken(token: token)
        _ivsChatManager.connectToChatRoom()
    }
    
    func sendChatMessage(call: FlutterMethodCall, result: FlutterResult){
        let message = call.arguments as! String
        _ivsChatManager.sendMessage(message, type: MessageType.message)
    }
    
    func leaveChatRoom(call: FlutterMethodCall, result: FlutterResult){
        _ivsChatManager.kick(user: "")
    }

    func toggleLocalAudioMute(call: FlutterMethodCall, result: FlutterResult){
        let isAudioMuted = _awsBoardcastView.toggleLocalAudioMute()
        result(isAudioMuted)
    }
    
    func toggleLocalVideoMute(call: FlutterMethodCall, result: FlutterResult){
        let isVideoMuted = _awsBoardcastView.toggleLocalVideoMute()
        result(isVideoMuted)
    }
    
    func initView(call: FlutterMethodCall, result: FlutterResult){
        _awsBoardcastView.initView()
        result(true)
    }
    
    func joinStage(call: FlutterMethodCall, result: FlutterResult){
        _awsBoardcastView.joinStage(token: call.arguments as! String)
        result(true)
    }
    
    func leaveStage(call: FlutterMethodCall, result: FlutterResult){
        _awsBoardcastView.leaveStage()
        result(true)
    }
    
}

extension FlutterAwsIvsView : AWSBroadcastViewStateProtocol {
    func onError() {
        self._methodChannel.invokeMethod("onError", arguments: nil)
    }
    
    func onConnectionStateChanged(connectionState: IVSStageConnectionState) {
        self._methodChannel.invokeMethod("onConnectionStateChanged", arguments: connectionState.rawValue)
    }
    
    func onLocalAudioStateChanged(isMuted: Bool) {
        self._methodChannel.invokeMethod("onLocalAudioStateChanged", arguments: isMuted)
    }
    
    func onLocalVideoStateChanged(isMuted: Bool) {
        self._methodChannel.invokeMethod("onLocalVideoStateChanged", arguments: isMuted)
    }
    
    func onBroadcastStateChanged(isBroadcasting: Bool) {
        self._methodChannel.invokeMethod("onBroadcastStateChanged", arguments: isBroadcasting)
    }
    
    
}
