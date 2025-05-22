import 'package:flutter/material.dart';
import 'package:mav_flutter/chat/chat_manager.dart';
import 'package:mav_flutter/chat/chat_service.dart';
import 'package:mav_flutter/chat/chat_ui.dart';
import 'package:mav_flutter/model/get_participants_response_model.dart';
import 'package:mav_flutter/widgets/participant_list_widget.dart';

class ChatAndParticipantsSheet extends StatefulWidget {
  final ChatManager chatManager;
  final ChatService chatService;
  final Function(String) onSendMessage;
  final Map<String, Map<String, Participant>>? participants;

  const ChatAndParticipantsSheet({
    super.key,
    required this.chatManager,
    required this.chatService,
    required this.onSendMessage, required this.participants,
  });

  @override
  State<ChatAndParticipantsSheet> createState() => _ChatAndParticipantsSheetState();
}

class _ChatAndParticipantsSheetState extends State<ChatAndParticipantsSheet> {
  int selectedTab = 0; // 0 = Chats, 1 = Participants

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFFF2EFED),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildTabButton(
                  label: 'Chats',
                  selected: selectedTab == 0,
                  onTap: () => setState(() => selectedTab = 0),
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  label: 'Participants (${widget.participants?.length ?? 0})',
                  selected: selectedTab == 1,
                  onTap: () => setState(() => selectedTab = 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: selectedTab == 0
                ? ChatUI(
                    chatManager: widget.chatManager,
                    chatService: widget.chatService,
                    onSendMessage: widget.onSendMessage,
                  )
                : ParticipantsListWidget(participants: widget.participants),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF6B1B) : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}