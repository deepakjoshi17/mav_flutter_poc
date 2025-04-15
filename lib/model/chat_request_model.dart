class ChatRequestModel {

  final String meetingId;
  final bool isModerator;

  ChatRequestModel({this.meetingId = '', this.isModerator = false});

  factory ChatRequestModel.fromJson(Map<String, dynamic> json) {
    return ChatRequestModel(
      meetingId: json['meetingId'] as String,
      isModerator: json['isModerator'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['meetingId'] = meetingId;
    data['isModerator'] = isModerator;
    return data;
  }
}