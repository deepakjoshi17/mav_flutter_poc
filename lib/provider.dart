import 'package:bhanzu_network/core/network_client.dart';
import 'package:bhanzu_network/data/response_model.dart';
import 'package:mav_flutter/common/api_urls.dart';
import 'package:mav_flutter/model/chat_logs_response_model.dart';
import 'package:mav_flutter/model/chat_request_model.dart';
import 'package:mav_flutter/model/create_chat_token_response_model.dart';
import 'package:mav_flutter/model/join_meeting_request_model.dart';
import 'package:mav_flutter/model/join_meeting_response_model.dart';

class DataProvider {

  final NetworkClient _client = NetworkClient.getInstance();

  Future<ResponseModel<JoinMeetingResponseModel>> joinMeeting(JoinMeetingRequestModel joinMeetingRequestModel) {
    return _client.makeRequest(
        baseUrl: ApiUrls.baseUrl,
        url: ApiUrls.joinMeeting,
        data: joinMeetingRequestModel.toJson(),
        requestMethod: RequestMethod.post,
        createData: (json) {
          return JoinMeetingResponseModel.fromJson(json);
        });
  }

  Future<ResponseModel<CreateChatTokenResponseModel>> createChatToken(ChatRequestModel  chatRequestModel) {
    return _client.makeRequest(
        baseUrl: ApiUrls.baseUrl,
        url: ApiUrls.createChatToken,
        data: chatRequestModel.toJson(),
        requestMethod: RequestMethod.post,
        createData: (json) {
          return CreateChatTokenResponseModel.fromJson(json);
        });
  }

  Future<ResponseModel<ChatLogsResponseModel>> getChatLogs(String meetingId) {
    return _client.makeRequest(
        baseUrl: ApiUrls.baseUrl,
        url: ApiUrls.getChatLogs,
        data: {"meetingId": meetingId},
        requestMethod: RequestMethod.post,
        createData: (json) {
          return ChatLogsResponseModel.fromJson(json);
        });
  }
}