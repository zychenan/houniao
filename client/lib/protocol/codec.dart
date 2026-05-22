import 'dart:convert';
import 'message.dart';

Message decodeMessage(String raw) {
  final j = jsonDecode(raw) as Map<String, dynamic>;
  return Message(
    type: j['type'], id: j['id'], time: j['time'], data: j['data'],
  );
}

String encodeMessage(Message msg) => jsonEncode(msg.toJson());

String encodeItemPush(String msgId, ItemPushData data) =>
    jsonEncode({'type': 'item_push', 'id': msgId, 'time': DateTime.now().millisecondsSinceEpoch, 'data': data.toJson()});

String encodePullHistory(String msgId, PullHistoryData data) =>
    jsonEncode({'type': 'pull_history', 'id': msgId, 'time': DateTime.now().millisecondsSinceEpoch, 'data': data.toJson()});
