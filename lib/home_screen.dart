import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mav_flutter/chat/chat_manager.dart';
import 'package:mav_flutter/chat/chat_service.dart';
import 'package:mav_flutter/chat/chat_ui.dart';
import 'package:mav_flutter/ios/controllers/flutter_aws_ivs_controller.dart';
import 'package:mav_flutter/model/chat_logs_response_model.dart';
import 'package:mav_flutter/model/chat_request_model.dart';
import 'package:mav_flutter/model/create_chat_token_response_model.dart';
import 'package:mav_flutter/model/get_participants_response_model.dart';
import 'package:mav_flutter/model/join_meeting_request_model.dart';
import 'package:mav_flutter/model/join_meeting_response_model.dart';
import 'package:mav_flutter/provider.dart';
import 'package:mav_flutter/widgets/custom_app_bar.dart';
import 'package:mav_flutter/widgets/session_feedback_sheet.dart';
import 'package:mav_flutter/widgets/meeting_ended_sheet.dart';

class VideoDevice {
  final String label;
  final String id;
  VideoDevice({required this.label, required this.id});

  factory VideoDevice.fromMap(Map<dynamic, dynamic> map) {
    return VideoDevice(
      label: map['label'] as String,
      id: map['id'] as String,
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
  late ChatManager _chatManager;
  late ChatService _chatService;
  final List<ChatMessage> _chatMessages = [];

  // This is used in the platform side to register the view.
  final String viewType = 'native_ivs_view_android';

  // Pass parameters to the platform side.
  final Map<String, dynamic> creationParams = <String, dynamic>{};

  bool isAudioMuted = false,
      isVideoMuted = false,
      screenSharing = false,
      stageJoined = false;

  DataProvider dataProvider = DataProvider();

  String meetingId = "deepak-154";
  String userName = "Marylin Monroe";
  String ownUserId = "admin-me@expinfi.com";
  String chatToken = '', videoToken = '', screenShareToken = '';

  DateTime nextSessionDateTime = DateTime(2025, 1, 24, 15, 0);

  bool showInAppLoader = false;

  CreateChatTokenResponseModel? createChatTokenResponse;
  JoinMeetingResponseModel? joinMeetingResponse;
  GetParticipantsResponseModel? participantsResponse;

  bool isLoading = false;

  // Add these variables for device management
  String? selectedAudioDevice;
  String? selectedVideoDevice;
  List<String> availableAudioDevices = [];
  List<String> availableVideoDevices = [];
  bool isAudioDropdownOpen = false;
  bool isVideoDropdownOpen = false;

  VideoDevice? selectedVideoDeviceObj;
  List<VideoDevice> availableVideoDeviceObjs = [];

  Future<void> initializeMeeting() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Initialize chat manager and service
      _chatManager = ChatManager(ownUserId);
      _chatService = ChatService(initialMessages: _chatMessages);
      _setupChatListener();

      // Initialize local participant
      executeIvsOperations("initLocalParticipant", args: {
        "name": userName,
        'userId': ownUserId,
      });

      // Prepare request models
      final joinMeetingRequestModel = JoinMeetingRequestModel(
          meetingId: meetingId, name: userName, sessionType: "LiveClass");
      final chatRequestModel = ChatRequestModel(
        meetingId: meetingId,
        isModerator: false,
      );

      // Call all APIs concurrently
      final fetchTokens = await Future.wait([
        dataProvider.joinMeeting(joinMeetingRequestModel),
        dataProvider.createChatToken(chatRequestModel),
      ]);

      // Handle join meeting response
      final joinMeetingResponse = fetchTokens[0].data as JoinMeetingResponseModel?;
      videoToken = joinMeetingResponse?.stageConfigs?.user?.token ?? "";
      screenShareToken = joinMeetingResponse?.stageConfigs?.display?.token ?? "";
      this.joinMeetingResponse = joinMeetingResponse;
      log("----------->>>>>>> User Token: ${videoToken.isEmpty ? 'empty' : 'Not empty'}");
      log("----------->>>>>>> Display Token: ${screenShareToken.isEmpty ? 'empty' : 'Not empty'}");

      // Handle chat token response
      final chatTokenResponse = fetchTokens[1].data as CreateChatTokenResponseModel?;
      createChatTokenResponse = chatTokenResponse;
      chatToken = chatTokenResponse?.token ?? "";
      log("----------->>>>>>> Chat token: ${chatToken.isEmpty ? 'empty' : 'Not empty'}");

      final fetchMeetingData = await Future.wait([
        dataProvider.getParticipants(meetingId),
        dataProvider.getChatLogs(meetingId)
      ]);

      // Handle participants response
      final participantsResponse = fetchMeetingData[0].data as GetParticipantsResponseModel?;
      this.participantsResponse = participantsResponse;
      log("----------->>>>>>> Participants: ${participantsResponse?.participants.user.length ?? 0}");

      // Handle chat logs response
      final chatLogsResponse = fetchMeetingData[1].data as ChatLogsResponseModel?;
      log("----------->>>>>>> Chat logs length: ${chatLogsResponse?.events.length ?? 0}");
      if (chatLogsResponse != null) {
        final events = chatLogsResponse.events;
        for (var event in events) {
          if (event.type == "MESSAGE" &&
              event.payload.type == "MESSAGE" &&
              event.payload.attributes['messageType'] == "chatMessage") {
            final message = ChatMessage(
              content: event.payload.content,
              isSent: event.payload.sender.userId == ownUserId,
              timestamp: DateTime.parse(event.payload.sendTime),
              id: event.payload.id,
              attributes: {
                'messageType': event.payload.attributes['messageType'],
                'displayName': event.payload.sender.attributes['displayName'],
              },
            );
            _chatService.addMessage(message);
          }
        }
      }

    } catch (e) {
      log("Error initializing meeting: $e");
      // You might want to show an error dialog here
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initializeMeeting();
    _initializeDevices();
  }

  Future<void> _initializeDevices() async {
    try {
      if (Platform.isIOS) {

      } else {
        // For Android, get devices as list of maps for video
        final audioDevices = await platform.invokeMethod<List<dynamic>>('getAudioDevices');
        final videoDevicesRaw = await platform.invokeMethod<List<dynamic>>('getVideoDevices');
        final videoDevices = videoDevicesRaw?.map((e) => VideoDevice.fromMap(e)).toList() ?? [];
        setState(() {
          availableAudioDevices = audioDevices?.cast<String>() ?? [];
          availableVideoDeviceObjs = videoDevices;
          if (availableAudioDevices.isNotEmpty) selectedAudioDevice = availableAudioDevices.first;
          if (availableVideoDeviceObjs.isNotEmpty) selectedVideoDeviceObj = availableVideoDeviceObjs.first;
        });
      }
    } catch (e) {
      log("Error getting devices: $e");
    }
  }

  Future<void> _switchDevice(String deviceId, bool isAudio) async {
    try {
      if (Platform.isIOS) {
        await platform.invokeMethod(isAudio ? 'switchAudioDevice' : 'switchVideoDevice', {
          'deviceId': deviceId
        });
      } else {
        await platform.invokeMethod(isAudio ? 'switchAudioDevice' : 'switchVideoDevice', {
          'deviceId': deviceId
        });
      }
      setState(() {
        if (isAudio) {
          selectedAudioDevice = deviceId;
        } else {
          selectedVideoDeviceObj = availableVideoDeviceObjs.firstWhere((d) => d.id == deviceId, orElse: () => availableVideoDeviceObjs.first);
        }
      });
    } catch (e) {
      log("Error switching device: $e");
    }
  }

  void _setupChatListener() {
    _chatManager.chatMessages.listen((message) {
      setState(() {
        if(message.messageType == "chatMessage") {
          _chatMessages.add(message);
        }
        else {
          switch(message.content) {
            case "LAUNCH_SESSION_FEEDBACK":
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const SessionFeedbackSheet(),
              );
              break;
            case "END_MEETING_FOR_ALL":
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (context) => MeetingEndedSheet(
                  moduleName: widget.title,
                  nextSessionDateTime: nextSessionDateTime,
                ),
              ));
              break;
            case "REMOVE_PARTICIPANT_FROM_SPOTLIGHT":
              break;
            default:
          }
        }
      });
    });
  }

  void _handleSendMessage(String message) {
    executeIvsOperations("sendMessage", args: {
      "message": message,
      "messageType": "chatMessage",
      "senderId": ownUserId,
    });
  }

  @override
  void dispose() {
    _chatManager.dispose();
    _chatService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: CustomAppBar(
            moduleName: widget.title,
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: <Widget>[
                Expanded(
                  child: getStreamingWidget(),
                ),
              ],
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF15D22)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Initializing meeting...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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

    if(stageJoined) {
      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          getPlatformView(),
          getControls(),
        ],
      );
    }
    else {
      return getPreviewWidget();
    }
  }

  Widget getPreviewWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text("Module 3 - Session 8",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  )),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  children: List.generate(participantsResponse?.participants.user.length ?? 0, (index) {
                    final user = participantsResponse?.participants.user;
                    final participant = participantsResponse?.participants.user.values.elementAt(index) as Map<String, Participant>;
                    final attributes = participant.values.first.attributes;
                    final name = attributes['name'] ?? 'N A';
                    final formattedName = name.split(' ').map((e) => e[0]).take(2).join().toString();

                    log("User: $user, participant: $participant, attributes: $attributes, name: $name");
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFF15D22),
                        child: Text(
                          formattedName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.45,
                width: MediaQuery.of(context).size.width * 0.6,
                decoration: BoxDecoration(
                  color: Color(0xFFF2EFED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFF15D22), width: 5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: getPlatformView(),
                ),
              ),
              const SizedBox(height: 16),
              getPreJoinControls(),
            ],
          ),
          const SizedBox(),
          buildJoinClassButton(() {
            setState(() {
              stageJoined = true;
            });
            executeIvsOperations("joinStage", args: {
              "videoToken": videoToken,
              "chatToken": chatToken,
              'audioMuted': isAudioMuted,
              'videoMuted': isVideoMuted,
              "region": "us-east-1",
            });
          }),
        ],
      ),
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
            getAudioButton(),
            getVideoButton(),
            getChatButton(),
            getScreenShareButton(),
            sharpenUpButton(),
            joinOrLeaveStageButton(),
          ],
        ),
      ),
    );
  }

  Widget getPreJoinControls() {
    return SafeArea(
      child: Container(
        width: double.maxFinite,
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            getPreviewAudioButton(),
            const SizedBox(width: 8),
            getPreviewVideoButton(),
          ],
        ),
      ),
    );
  }

  Widget getScreenShareButton() {
    return getControlButton(
        screenSharing
            ? Icons.browser_not_supported
            : Icons.screen_lock_landscape, () {
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
    }, color: screenSharing ? Colors.white : Colors.grey);
  }

  Widget getAudioButton() {
    return getControlButton(
        isAudioMuted ? Icons.mic_off_rounded : Icons.mic_outlined, () {
      executeIvsOperations("toggleMic");
      setState(() {
        isAudioMuted = !isAudioMuted;
      });
    }, color: isAudioMuted ? Colors.grey : Color(0xFFF15D22));
  }

  Widget getPreviewAudioButton() {
    return getMicCamControlButton(
      isAudioMuted ? Icons.mic_off_rounded : Icons.mic_outlined,
      () {
        executeIvsOperations("toggleMic");
        setState(() {
          isAudioMuted = !isAudioMuted;
        });
      },
      color: isAudioMuted ? Colors.grey : Colors.red,
      isAudio: true,
    );
  }

  Widget getVideoButton() {
    return getControlButton(isVideoMuted ? Icons.videocam_off : Icons.videocam,
        () {
      executeIvsOperations("toggleCamera");
      setState(() {
        isVideoMuted = !isVideoMuted;
      });
    }, color: isVideoMuted ? Colors.grey : Color(0xFFF15D22));
  }

  Widget getPreviewVideoButton() {
    return getMicCamControlButton(
      isVideoMuted ? Icons.videocam_off : Icons.videocam,
      () {
        executeIvsOperations("toggleCamera");
        setState(() {
          isVideoMuted = !isVideoMuted;
        });
      },
      color: isVideoMuted ? Colors.grey : Colors.red,
      isAudio: false,
    );
  }

  Widget getChatButton() {
    return getControlButton(Icons.chat, () {
      openChat();
    }, color: Colors.grey);
  }

  Widget joinOrLeaveStageButton() {
    return getControlButton(
        stageJoined ? Icons.exit_to_app_outlined : Icons.start, () {
      if (stageJoined) {
        setState(() {
          stageJoined = false;
        });
        executeIvsOperations("leaveStage");
      } else {
        setState(() {
          stageJoined = true;
        });
        executeIvsOperations("joinStage", args: {
          "videoToken": videoToken,
          "chatToken": chatToken,
          'audioMuted': isAudioMuted,
          'videoMuted': isVideoMuted,
          "region": "us-east-1",
        });
      }
    }, color: stageJoined ? Colors.red : Colors.grey);
  }

  void executeIvsOperations(String methodName, {dynamic args}) {
    if (Platform.isIOS) {
      switch (methodName) {
        case "joinStage":
          final participantToken = args['videoToken'] ?? '';
          final chatToken = args['chatToken'] ?? '';
          iosIvsController?.joinStage(participantToken);
          iosIvsController?.joinChatRoom(chatToken, "us-east-1");
          break;
        case "leaveStage":
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

  Widget getMicCamControlButton(IconData icon, Function() onTap,
      {Color color = Colors.grey, bool isAudio = true}) {
    final devices = isAudio
        ? availableAudioDevices
        : availableVideoDeviceObjs.map((d) => d.label).toList();
    final selectedDevice = isAudio
        ? selectedAudioDevice
        : selectedVideoDeviceObj?.label;
    final isDropdownOpen = isAudio ? isAudioDropdownOpen : isVideoDropdownOpen;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide.none,
            ),
            onSelected: (String deviceLabel) {
              if (isAudio) {
                _switchDevice(deviceLabel, true);
              } else {
                final device = availableVideoDeviceObjs.firstWhere((d) => d.label == deviceLabel, orElse: () => availableVideoDeviceObjs.first);
                _switchDevice(device.id, false);
              }
              setState(() {
                if (isAudio) {
                  isAudioDropdownOpen = false;
                } else {
                  isVideoDropdownOpen = false;
                }
              });
            },
            onCanceled: () {
              setState(() {
                if (isAudio) {
                  isAudioDropdownOpen = false;
                } else {
                  isVideoDropdownOpen = false;
                }
              });
            },
            onOpened: () {
              setState(() {
                if (isAudio) {
                  isAudioDropdownOpen = true;
                } else {
                  isVideoDropdownOpen = true;
                }
              });
            },
            itemBuilder: (BuildContext context) => devices.map((String device) {
              return PopupMenuItem<String>(
                value: device,
                child: Row(
                  children: [
                    Text(
                      device,
                      style: TextStyle(
                        color: device == selectedDevice ? Color(0xFFF15D22) : Colors.black,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: EdgeInsets.only(left: 8, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: isDropdownOpen ? Color(0xFFF2EFED) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedDevice == null ? 'NA' : '',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Icon(
                    isDropdownOpen ? Icons.arrow_drop_up_sharp : Icons.arrow_drop_down_sharp,
                    size: 24,
                    color: Color(0xFFF15D22),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getControlButton(IconData icon, Function() onTap,
      {Color color = Colors.grey}) {
    return InkWell(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ChatUI(
          chatManager: _chatManager,
          chatService: _chatService,
          onSendMessage: _handleSendMessage,
        ),
      ),
    );
  }

  Widget sharpenUpButton() {
    return getControlButton(Icons.ad_units_outlined, () {
      //Open bottom sheet with a webview
      showModalBottomSheet(
        context: context,
        enableDrag: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Stack(
            children: [
              Container(
                color: Colors.white,
                child: //show webview
                    InAppWebView(
                        initialUrlRequest: URLRequest(
                          url: WebUri("https://www.bhanzu.com"),
                        ),
                        onLoadStart: (_, url) {
                          setState(() {
                            showInAppLoader = true;
                          });
                        },
                        onLoadStop: (_, url) {
                          setState(() {
                            showInAppLoader = false;
                          });
                        }),
              ),
              if (showInAppLoader)
                Center(
                  child: CircularProgressIndicator(color: Colors.grey,),
                ),
            ],
          ),
        ),
      );
    }, color: Colors.grey);
  }

  Widget buildJoinClassButton(Function() onTap) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE94E1B), // Orange color
          foregroundColor: Colors.white, // Text color
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22), // Fully rounded
          ),
          shadowColor: const Color(0xFFB23A13), // Shadow color
          padding: const EdgeInsets.symmetric(horizontal: 32),
        ),
        child: const Text(
          'Join Class',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
