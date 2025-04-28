import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mav_flutter/model/chat_request_model.dart';
import 'package:mav_flutter/model/create_chat_token_response_model.dart';
import 'package:mav_flutter/model/join_meeting_request_model.dart';
import 'package:mav_flutter/model/join_meeting_response_model.dart';
import 'package:mav_flutter/provider.dart';

import 'ios/controllers/flutter_aws_ivs_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // This is used in the platform side to register the view.
  static const platform = MethodChannel('mav_flutter/controls');
  FlutterAwsIvsController? iosIvsController;

  // This is used in the platform side to register the view.
  final String viewType = 'native_ivs_view_android';

  // Pass parameters to the platform side.
  final Map<String, dynamic> creationParams = <String, dynamic>{};

  bool isAudioMuted = false,
      isVideoMuted = false,
      screenSharing = false,
      stageJoined = false;

  DataProvider dataProvider = DataProvider();

  String meetingId = "deepak-148";
  String chatToken = '', videoToken = '', screenShareToken = '';

  CreateChatTokenResponseModel? createChatTokenResponse;
  JoinMeetingResponseModel? joinMeetingResponse;

  @override
  void initState() {
    super.initState();

    var joinMeetingResponseModel = JoinMeetingRequestModel(
        meetingId: meetingId, name: "John Doe", sessionType: "LiveClass");
    dataProvider.joinMeeting(joinMeetingResponseModel).then((value) {
      setState(() {
        videoToken = value.data?.stageConfigs?.user?.token ?? "";
        screenShareToken = value.data?.stageConfigs?.display?.token ?? "";
        joinMeetingResponse = value.data;
        log("User Token: $videoToken");
        log("Display Token: $screenShareToken");
      });
    });

    var chatRequestModel = ChatRequestModel(
      meetingId: meetingId,
      isModerator: false,
    );
    dataProvider.createChatToken(chatRequestModel).then((value) {
      setState(() {
        createChatTokenResponse = value.data;
        chatToken = value.data?.token ?? "";
        log("Chat Token: $chatToken");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          Expanded(
            child: getStreamingWidget(),
          ),
        ],
      ),
    );
  }

  Widget getPlatformView() {
    if (Platform.isIOS) {
      return UiKitView(
        viewType: 'flutter_aws_ivs',
        onPlatformViewCreated: (int id) {
          if (iosIvsController != null) {
            iosIvsController!.initView();
            return;
          }
          iosIvsController = FlutterAwsIvsController.init(id);
          iosIvsController!.initView();
        },
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      return AndroidView(
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
  }

  Widget getStreamingWidget() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        getPlatformView(),
        getControls(),
      ],
    );
  }

  Widget getControls() {
    return SafeArea(
      child: Container(
        width: double.maxFinite,
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.indigo,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            getControlButton(
                isAudioMuted ? Icons.mic_off_rounded : Icons.mic_outlined, () {
              executeIvsOperations("toggleMic");
              setState(() {
                isAudioMuted = !isAudioMuted;
              });
            }),
            getControlButton(isVideoMuted ? Icons.videocam_off : Icons.videocam,
                () {
              executeIvsOperations("toggleCamera");
              setState(() {
                isVideoMuted = !isVideoMuted;
              });
            }),
            getControlButton(Icons.chat, () {
              executeIvsOperations("sendMessage", args: {
                "message": "Hello from Flutter",
                "messageType": "chatEvent"
              });
            }),
            getControlButton(
                stageJoined ? Icons.account_circle : Icons.no_accounts, () {
              if (stageJoined) {
                executeIvsOperations("leaveStage");
              } else {
                executeIvsOperations("joinStage", args: {
                  "videoToken": videoToken,
                  "chatToken": chatToken,
                  'audioMuted': isAudioMuted,
                  'videoMuted': isVideoMuted,
                  "region": "us-east-1",
                });
              }
            }),
            getControlButton(
                screenSharing
                    ? Icons.screen_lock_landscape
                    : Icons.browser_not_supported, () {
              if (screenSharing) {
                executeIvsOperations("stopScreenShare");
                setState(() {
                  screenSharing = false;
                });
              } else {
                executeIvsOperations("startScreenShare",
                    args: {"displayToken": screenShareToken});
                setState(() {
                  screenSharing = true;
                });
              }
            }),
          ],
        ),
      ),
    );
  }

  void executeIvsOperations(String methodName, {dynamic args}) {
    if (Platform.isIOS) {
      switch (methodName) {
        case "joinStage":
          setState(() {
            stageJoined = true;
          });
          final participantToken = args['videoToken'] ?? '';
          final chatToken = args['chatToken'] ?? '';
          iosIvsController?.joinStage(participantToken);
          iosIvsController?.joinChatRoom(chatToken, "us-east-1");
          break;
        case "leaveStage":
          setState(() {
            stageJoined = false;
          });
          iosIvsController?.leaveStage();
          iosIvsController?.leaveChatRoom();
          break;
        case "toggleMic":
          iosIvsController?.toggleLocalAudioMute();
          break;
        case "toggleCamera":
          iosIvsController?.toggleLocalVideoMute();
          break;
        case "sendMessage":
          final message = args['message'] ?? '';
          final messageType = args['messageType'] ?? '';
          iosIvsController?.sendChatMessage(message);
          break;
        default:
          log("Invalid Method: $methodName, returned: $args");
          break;
      }
    } else {
      invokePlatformMethod(methodName, args: args);
    }
  }

  void invokePlatformMethod(String methodName, {dynamic args}) async {
    try {
      final result = await platform.invokeMethod<String>(methodName, args);
      log("Method: $methodName, returned: $result");
    } on PlatformException catch (e) {
      log("Failed while running method: $methodName, with error: ${e.message}");
    }
  }

  Widget getControlButton(IconData icon, Function() onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 24,
            color: Colors.white,
          )),
    );
  }

  void openChat() {
    log("Chat to be implemented");
  }
}
