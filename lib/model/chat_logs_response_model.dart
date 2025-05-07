import 'package:bhanzu_network/utils/conversion_utils.dart';

class ChatLogsResponseModel {
  final String id;
  final String chatRoomArn;
  final List<ChatEvent> events;

  ChatLogsResponseModel({
    required this.id,
    required this.chatRoomArn,
    required this.events,
  });

  factory ChatLogsResponseModel.fromJson(Map<String, dynamic> json) {
    return ChatLogsResponseModel(
      id: ConversionUtils.getValueFromJson<String>(json, "id") ?? "",
      chatRoomArn: ConversionUtils.getValueFromJson<String>(json, "chatRoomArn") ?? "",
      events: (json["events"] as List?)?.map((e) => ChatEvent.fromJson(e)).toList() ?? [],
    );
  }
}

class ChatEvent {
  final String eventTimestamp;
  final String type;
  final ChatPayload payload;

  ChatEvent({
    required this.eventTimestamp,
    required this.type,
    required this.payload,
  });

  factory ChatEvent.fromJson(Map<String, dynamic> json) {
    return ChatEvent(
      eventTimestamp: ConversionUtils.getValueFromJson<String>(json, "event_timestamp") ?? "",
      type: ConversionUtils.getValueFromJson<String>(json, "type") ?? "",
      payload: ChatPayload.fromJson(json["payload"] ?? {}),
    );
  }
}

class ChatPayload {
  final String type;
  final String id;
  final String requestId;
  final Map<String, dynamic> attributes;
  final String content;
  final String sendTime;
  final ChatSender sender;

  ChatPayload({
    required this.type,
    required this.id,
    required this.requestId,
    required this.attributes,
    required this.content,
    required this.sendTime,
    required this.sender,
  });

  factory ChatPayload.fromJson(Map<String, dynamic> json) {
    return ChatPayload(
      type: ConversionUtils.getValueFromJson<String>(json, "Type") ?? "",
      id: ConversionUtils.getValueFromJson<String>(json, "Id") ?? "",
      requestId: ConversionUtils.getValueFromJson<String>(json, "RequestId") ?? "",
      attributes: json["Attributes"] ?? {},
      content: ConversionUtils.getValueFromJson<String>(json, "Content") ?? "",
      sendTime: ConversionUtils.getValueFromJson<String>(json, "SendTime") ?? "",
      sender: ChatSender.fromJson(json["Sender"] ?? {}),
    );
  }
}

class ChatSender {
  final String userId;
  final Map<String, dynamic> attributes;

  ChatSender({
    required this.userId,
    required this.attributes,
  });

  factory ChatSender.fromJson(Map<String, dynamic> json) {
    return ChatSender(
      userId: ConversionUtils.getValueFromJson<String>(json, "UserId") ?? "",
      attributes: json["Attributes"] ?? {},
    );
  }
} 