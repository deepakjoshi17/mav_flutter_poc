class GetParticipantsResponseModel {
  final String meetingId;
  final String recurrenceMeetingId;
  final String alias;
  final String stageArn;
  final int createdAt;
  final bool isActive;
  final Participants participants;
  final String roomType;

  GetParticipantsResponseModel({
    this.meetingId = '',
    this.recurrenceMeetingId = '',
    this.alias = '',
    this.stageArn = '',
    this.createdAt = 0,
    this.isActive = false,
    this.participants = const Participants(),
    this.roomType = '',
  });

  factory GetParticipantsResponseModel.fromJson(Map<String, dynamic> json) {
    return GetParticipantsResponseModel(
      meetingId: json['meetingId'] as String,
      recurrenceMeetingId: json['recurrenceMeetingId'] as String,
      alias: json['alias'] as String,
      stageArn: json['stageArn'] as String,
      createdAt: json['createdAt'] as int,
      isActive: json['isActive'] as bool,
      participants: Participants.fromJson(json['participants']),
      roomType: json['roomType'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['meetingId'] = meetingId;
    data['recurrenceMeetingId'] = recurrenceMeetingId;
    data['alias'] = alias;
    data['stageArn'] = stageArn;
    data['createdAt'] = createdAt;
    data['isActive'] = isActive;
    data['participants'] = participants.toJson();
    data['roomType'] = roomType;
    return data;
  }
}

class Participants {
  final Map<String, Map<String, Participant>> user;
  final Map<String, dynamic> display;

  const Participants({
    this.user = const {},
    this.display = const {},
  });

  factory Participants.fromJson(Map<String, dynamic> json) {
    final userMap = <String, Map<String, Participant>>{};
    if (json['user'] != null) {
      (json['user'] as Map<String, dynamic>).forEach((key, value) {
        userMap[key] = {
          key: Participant.fromJson(value as Map<String, dynamic>)
        };
      });
    }

    return Participants(
      user: userMap,
      display: json['display'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    final userMap = <String, dynamic>{};
    user.forEach((key, value) {
      userMap[key] = value[key]?.toJson();
    });
    data['user'] = userMap;
    data['display'] = display;
    return data;
  }
}

class Participant {
  final bool isPublishing;
  final Map<String, dynamic> attributes;
  final String id;

  Participant({
    this.isPublishing = false,
    this.attributes = const {},
    this.id = '',
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      isPublishing: json['isPublishing'] as bool,
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
      id: json['id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isPublishing'] = isPublishing;
    data['attributes'] = attributes;
    data['id'] = id;
    return data;
  }
} 