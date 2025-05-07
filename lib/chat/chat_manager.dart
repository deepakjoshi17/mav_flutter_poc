import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:mav_flutter/chat/chat_ui.dart';

class ChatManager {
  static const _eventChannel = EventChannel('mav_flutter/chat_messages');
  final _messageController = StreamController<ChatMessage>.broadcast();
  StreamSubscription? _subscription;

  ChatManager() {
    _setupEventChannel();
  }

  Stream<ChatMessage> get chatMessages => _messageController.stream;

  void _setupEventChannel() {
    _subscription = _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      log('-------->>>>>>> Chat event received: $event');
      if (event is Map) {
        final messageType = event['messageType'];
        if (messageType == 'chatMessage') {
          final content = event['content'] as String?;
          final sender = event['sender'] as String?;
          final id = event['id'] as String?;
          final isSent = event['isSent'] as bool? ?? false;
          final timestamp = event['timestamp'] as String?;
          if (content != null) {
            _messageController.add(ChatMessage(
              content: content,
              isSent: isSent,
              timestamp: timestamp != null ? DateTime.parse(timestamp) : DateTime.now(),
              id: id,
              attributes: {
                'messageType': messageType,
                'sender': sender,
              },
            ));
          }
        }
      }
    }, onError: (dynamic error) {
      print('Error in chat event channel: $error');
    });
  }

  void dispose() {
    _subscription?.cancel();
    _messageController.close();
  }
} 