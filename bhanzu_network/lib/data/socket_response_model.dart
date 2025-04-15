class SocketResponseModel<T> {}

class ConnectedToSocket<T> extends SocketResponseModel<T> {
  final T? data;

  ConnectedToSocket({required this.data});
}

class DisconnectedFromSocket<T> extends SocketResponseModel<T> {
  final T? data;

  DisconnectedFromSocket({required this.data});
}

class ErrorInSocket<T> extends SocketResponseModel<T> {
  final T? data;
  final String? error;

  ErrorInSocket({required this.data, this.error});
}

class MessageReceived<T> extends SocketResponseModel<T> {
  final T data;

  MessageReceived({required this.data});
}
