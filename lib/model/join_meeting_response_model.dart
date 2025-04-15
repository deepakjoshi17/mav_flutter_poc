class JoinMeetingResponseModel {
  final StageConfigs? stageConfigs;
  final String stageArn;
  final String meetingId;
  final String recurrenceMeetingId;
  final String userId;
  final String displayId;
  final String role;
  final String name;

  JoinMeetingResponseModel({
    this.stageConfigs,
    this.stageArn = '',
    this.meetingId = '',
    this.recurrenceMeetingId = '',
    this.userId = '',
    this.displayId = '',
    this.role = '',
    this.name = '',
  });

  factory JoinMeetingResponseModel.fromJson(Map<String, dynamic> json) {
    return JoinMeetingResponseModel(
      stageConfigs: StageConfigs.fromJson(json['stageConfigs']),
      stageArn: json['stageArn'] as String,
      meetingId: json['meetingId'] as String,
      recurrenceMeetingId: json['recurrenceMeetingId'] as String,
      userId: json['userId'] as String,
      displayId: json['displayId'] as String,
      role: json['role'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['stageConfigs'] = stageConfigs?.toJson() ?? {};
    data['stageArn'] = stageArn;
    data['meetingId'] = meetingId;
    data['recurrenceMeetingId'] = recurrenceMeetingId;
    data['userId'] = userId;
    data['displayId'] = displayId;
    data['role'] = role;
    data['name'] = name;
    return data;
  }
}

class StageConfigs {
  final TokenModel? user;
  final TokenModel? display;

  StageConfigs({this.user, this.display});

  factory StageConfigs.fromJson(Map<String, dynamic> json) {
    return StageConfigs(
      user: TokenModel.fromJson(json['user']),
      display: TokenModel.fromJson(json['display']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user'] = user?.toJson() ?? {};
    data['display'] = display?.toJson() ?? {};
    return data;
  }
}

class TokenModel {
  final String token;
  final String participantId;
  final String participantGroup;

  TokenModel({this.token = '', this.participantId = '', this.participantGroup = ''});

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      token: json['token'] as String,
      participantId: json['participantId'] as String,
      participantGroup: json['participantGroup'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['token'] = token;
    data['participantId'] = participantId;
    data['participantGroup'] = participantGroup;
    return data;
  }
}