import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';
import 'package:houniao/protocol/codec.dart';
import 'package:houniao/protocol/message.dart';

class NetClient {
  WebSocketChannel? _channel;
  final _uuid = const Uuid();
  final _ackCompleters = <String, Completer<AckData>>{};
  final _messageController = StreamController<Message>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<Message> get messages => _messageController.stream;
  Stream<bool> get onConnectionChange => _connectionController.stream;
  bool get isConnected => _channel != null;

  Future<void> connect(String url, String deviceId, String deviceName) async {
    final wsUrl = Uri.parse(url);
    _channel = WebSocketChannel.connect(wsUrl);

    await _channel!.ready;
    _connectionController.add(true);

    // version_nego
    _channel!.sink.add(jsonEncode({
      'type': 'version_nego',
      'device_id': deviceId,
      'platform': 'flutter',
      'name': deviceName,
    }));

    _channel!.stream.listen(
      (raw) {
        final msg = decodeMessage(raw as String);
        _messageController.add(msg);

        if (msg.type == 'ack') {
          final ack = AckData.fromJson(msg.data as Map<String, dynamic>);
          final c = _ackCompleters.remove(ack.reqId);
          c?.complete(ack);
        }
      },
      onDone: () {
        _channel = null;
        _connectionController.add(false);
      },
      onError: (_) {
        _channel = null;
        _connectionController.add(false);
      },
    );
  }

  Future<AckData> sendAndWait(String type, Map<String, dynamic> data) async {
    final msgId = _uuid.v4();
    final msg = Message(type: type, id: msgId, time: DateTime.now().millisecondsSinceEpoch, data: data);

    final completer = Completer<AckData>();
    _ackCompleters[msgId] = completer;
    _channel?.sink.add(jsonEncode(msg.toJson()));

    return completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      _ackCompleters.remove(msgId);
      return AckData(reqId: msgId, status: -1, detail: 'timeout');
    });
  }

  void send(Message msg) {
    _channel?.sink.add(jsonEncode(msg.toJson()));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
