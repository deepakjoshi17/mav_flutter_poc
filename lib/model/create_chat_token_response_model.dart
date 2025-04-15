import 'package:bhanzu_network/utils/conversion_utils.dart';

class CreateChatTokenResponseModel {

  final List<String> capabilities;
  final String token;
  final String sessionExpirationTime;
  final String tokenExpirationTime;

  CreateChatTokenResponseModel({
    this.capabilities = const [],
    required this.token,
    required this.sessionExpirationTime,
    required this.tokenExpirationTime,
  });

  factory CreateChatTokenResponseModel.fromJson(Map<String, dynamic> json) {
    return CreateChatTokenResponseModel(
      capabilities: ConversionUtils.getValueFromJson<List<String>>(json, "capabilities") ?? [],
      token: ConversionUtils.getValueFromJson<String>(json, "token") ?? "",
      sessionExpirationTime: ConversionUtils.getValueFromJson<String>(json, "sessionExpirationTime") ?? "",
      tokenExpirationTime: ConversionUtils.getValueFromJson<String>(json, "tokenExpirationTime") ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['capabilities'] = capabilities;
    data['token'] = token;
    data['sessionExpirationTime'] = sessionExpirationTime;
    data['tokenExpirationTime'] = tokenExpirationTime;
    return data;
  }
}