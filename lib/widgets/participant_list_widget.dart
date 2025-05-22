import 'package:flutter/material.dart';
import 'package:mav_flutter/common/utils.dart';
import 'package:mav_flutter/model/get_participants_response_model.dart';

class ParticipantsListWidget extends StatelessWidget {

  final Map<String, Map<String, Participant>>? participants;
  const ParticipantsListWidget({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {

    return ListView.builder(
      itemCount: participants?.length ?? 0,
      itemBuilder: (context, index) {
        final participant = participants?.values.elementAt(index).values.first;
        final participantName = participant?.attributes['name']?.toString() ?? (participant?.attributes['displayName']?.toString() ?? "NA");
        final participantInitials = Utils.getNameInitials(participantName);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            dense: true,
            title: Text(participantName),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            // subtitle: Text(participant?.attributes['role']?.toString() ?? 'No role'),
            leading: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF5E91FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FittedBox(child: Text('DJ', textAlign: TextAlign.center, maxLines: 1, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14))),
            ),
          ),
        );
      },
    );
  }
}