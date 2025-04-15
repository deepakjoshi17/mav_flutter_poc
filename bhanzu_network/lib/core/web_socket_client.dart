import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bhanzu_network/core/network_client.dart';
import 'package:bhanzu_network/data/socket_response_model.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

class SocketNetworkClient<T> {
  final String serverUrl;
  final String roomId;
  final String origin;
  final Map<String, String> extras;

  final T Function(dynamic json) createData;
  late IOWebSocketChannel channel;
  Function onReconnect;

  StreamController<SocketResponseModel<T>> _streamController =
      StreamController<SocketResponseModel<T>>();

  StreamController<SocketResponseModel<T>> get messageStream =>
      _streamController;

  SocketNetworkClient({
    required this.serverUrl,
    required this.roomId,
    required this.createData,
    required this.origin,
    this.extras = const {},
    required this.onReconnect,
  });

  bool isConnectionActive = false;

  Future<void> connectToSocket() async {
    _streamController = StreamController<SocketResponseModel<T>>();
    final Map<String, dynamic> header = NetworkClient.getCookieHeader() ?? {};
    header['Origin'] = origin;

    log('Trying to connect to the socket server: \n Url: $serverUrl/?room=$roomId');
    channel = IOWebSocketChannel.connect(
      "$serverUrl/?room=$roomId",
      headers: header,
      pingInterval: const Duration(minutes: 1),
      connectTimeout: const Duration(minutes: 1),
    );

    await channel.ready;
    isConnectionActive = true;

    log('Connected to the socket server: \n Url: $serverUrl/?room=$roomId  \n Cookie: $header');
    channel.stream.listen((message) {
      log('Received message from the socket server : $message');
      try {
        final data = createData(jsonDecode(message));
        _streamController.add(MessageReceived(data: data));
        log('Message added to the stream controller');
      } catch (e) {
        log('Error parsing message from the socket server : $e');
      }
    }, onDone: () {
      log('Socket connection closed');
      isConnectionActive = false;
      _streamController.add(DisconnectedFromSocket(data: null));
    }, onError: (error) {
      log('Socket connection error: $error');
      isConnectionActive = false;
      _streamController.add(ErrorInSocket(data: null, error: error.toString()));
    });
  }

  Future<void> sendMessage(
    Map<String, dynamic> req,
  ) async {
    if (isConnectionActive == false) {
      log('Socket connection is not active. Trying to reconnect.');
      await connectToSocket();
      onReconnect();
    }

    try {
      req.addAll(extras);
      req.addAll({
        "action": "gameUpdate",
        "requestContext": {"routeKey": "gameUpdate"},
      });
      final json = jsonEncode(req);
      channel.sink.add(json);
      log('Sent message to the socket server : $json');
    } catch (e) {
      log('Error sending message to the socket server : $e', error: e);
    }
  }

  void dispose() {
    channel.sink.close(status.goingAway);
  }
}
