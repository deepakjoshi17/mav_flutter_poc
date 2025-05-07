import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
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
      widget.chatService.addMessage(ChatMessage(
        content: message,
        isSent: true,
        timestamp: DateTime.now(),
      ));
      widget.onSendMessage(message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Align(
                    alignment: message.isSent ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: message.isSent ? Colors.blue : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Column(
                        crossAxisAlignment: message.isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.content,
                            style: TextStyle(
                              color: message.isSent ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.formattedTime,
                            style: TextStyle(
                              color: message.isSent ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isSent;
  final DateTime timestamp;
  final String id;
  final Map<String, dynamic>? attributes;

  ChatMessage({
    required this.content,
    required this.isSent,
    required this.timestamp,
    String? id,
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