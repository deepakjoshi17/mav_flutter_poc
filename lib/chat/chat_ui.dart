import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mav_flutter/chat/chat_manager.dart';
import 'package:mav_flutter/chat/chat_service.dart';

class ChatUI extends StatefulWidget {
  final ChatManager chatManager;
  final ChatService chatService;
  final Function(String) onSendMessage;

  const ChatUI({
    super.key,
    required this.chatManager,
    required this.chatService,
    required this.onSendMessage,
  });

  @override
  State<ChatUI> createState() => _ChatUIState();
}

class _ChatUIState extends State<ChatUI> {
  final TextEditingController _messageController = TextEditingController();
  late StreamSubscription<ChatMessage> _messagesSubscription;
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Initialize with existing messages
    _messages.addAll(widget.chatService.currentMessages);

    _messagesSubscription = widget.chatService.messages.listen((messages) {
      setState(() {
        _messages.add(messages);
      });
    });

    /*// Listen to incoming messages from the chat manager
    widget.chatManager.chatMessages.listen((message) {
      widget.chatService.addMessage(ChatMessage(
        content: message.content,
        isSent: false,
        timestamp: DateTime.now(),
      ));
    });*/
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messagesSubscription.cancel();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      final message = _messageController.text;
      /*widget.chatService.addMessage(ChatMessage(
        content: message,
        isSent: true,
        timestamp: DateTime.now(),
      ));*/
      widget.onSendMessage(message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: _messages.isEmpty
          ? getEmptyScreen()
          : getChatList(),
    );
  }

  Widget getSendButton() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    margin:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFF908B85),
        width: 1.5,
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            style: const TextStyle(
                color: Colors.black, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Type a message...',
              hintStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _sendMessage(),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: SvgPicture.asset("assets/ic_happy_emoji.svg"),
        ),
        const SizedBox(width: 8.0),
        GestureDetector(
          onTap: _sendMessage,
          child: SvgPicture.asset("assets/ic_send_chat.svg"),
        )
      ],
    ),
  );

  Widget getEmptyScreen() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Spacer(),
      Image.asset(
        "assets/ic_empty_conversation.png",
        height: 50,
        width: 50,
      ),
      const SizedBox(height: 12),
      const Text(
        'Start a Conversation',
        style: TextStyle(
          color: Color(0xFF413930),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'There are no messages here yet. \nStart a conversation \nby sending a Message',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF908B85),
          fontSize: 12,
        ),
      ),
      Spacer(),
      Align(
          alignment: Alignment.bottomCenter,
          child: getSendButton()),
    ],
  );

  Widget getChatList() => Column(
    children: [
      Expanded(
        child: ListView.builder(
          reverse: true,
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final message = _messages[_messages.length - 1 - index];
            return Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 4.0, horizontal: 16),
              child: Column(
                crossAxisAlignment: message.isSent
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: !message.isSent,
                    child: Text(
                      message.attributes?['displayName'] ?? 'NA',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    constraints: BoxConstraints(
                      maxWidth:
                      MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: message.isSent
                          ? Colors.white
                          : Color(0xFFE5E1DE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                          color: Color(0xFF413930), fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.formattedTime,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      getSendButton(),
    ],
  );
}

class ChatMessage {
  final String content;
  final bool isSent;
  final DateTime timestamp;
  final String id;
  final String messageType;
  final Map<String, dynamic>? attributes;

  ChatMessage({
    required this.content,
    required this.isSent,
    required this.timestamp,
    String? id,
    this.messageType = '',
    this.attributes,
  }) : id = id ?? '${timestamp.millisecondsSinceEpoch}_${content.hashCode}';

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    final timeFormat = DateFormat('hh:mm a');
    final dateTimeFormat = DateFormat('dd MMM hh:mm a');

    if (difference.inDays < 1) {
      return timeFormat.format(timestamp);
    } else {
      return dateTimeFormat.format(timestamp);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
