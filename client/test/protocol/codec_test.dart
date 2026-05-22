import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:houniao/protocol/codec.dart';
import 'package:houniao/protocol/message.dart';

void main() {
  test('decode item_broadcast', () {
    final raw = '{"type":"item_broadcast","id":"x","time":1,"data":{"module_type":"clipboard","content":"hi","device_id":"d1","device_name":"phone","seq_no":1,"created_at":100}}';
    final msg = decodeMessage(raw);
    expect(msg.type, 'item_broadcast');
    final data = ItemBroadcastData.fromJson(msg.data as Map<String, dynamic>);
    expect(data.content, 'hi');
    expect(data.seqNo, 1);
  });

  test('encode item_push', () {
    final raw = encodeItemPush('m1', const ItemPushData(moduleType: 'clipboard', content: 'test'));
    final j = jsonDecode(raw) as Map<String, dynamic>;
    expect(j['type'], 'item_push');
    expect((j['data'] as Map)['content'], 'test');
  });
}
