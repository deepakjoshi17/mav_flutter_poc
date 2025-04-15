class JoinMeetingRequestModel {

  final String sessionType;
  final String meetingId;
  final String name;

  JoinMeetingRequestModel({this.sessionType = '', this.meetingId = '', this.name = ''});

  factory JoinMeetingRequestModel.fromJson(Map<String, dynamic> json) {
    return JoinMeetingRequestModel(
      sessionType: json['sessionType'] as String,
      meetingId: json['meetingId'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sessionType'] = sessionType;
    data['meetingId'] = meetingId;
    data['name'] = name;
    return data;
  }
}