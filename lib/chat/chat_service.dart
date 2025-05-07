import 'dart:async';
import 'dart:developer';

import 'chat_ui.dart';

class ChatService {
  final List<ChatMessage> _messages;
  final _messageController = StreamController<ChatMessage>.broadcast();

  ChatService({List<ChatMessage>? initialMessages})
      : _messages = initialMessages ?? [];

  Stream<ChatMessage> get messages => _messageController.stream;

  List<ChatMessage> get currentMessages => List.unmodifiable(_messages);

  void addMessage(ChatMessage message) {
    // Check if message with same ID already exists

    if (!_messages.any((m) => m.id == message.id)) {
      _messages.add(message);
      _messageController.add(message);
    }
  }

  void clearMessages() {
    _messages.clear();
    _messageController.close();
  }

  void dispose() {
    _messageController.close();
  }
}