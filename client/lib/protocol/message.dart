class Message {
  final String type;
  final String id;
  final int time;
  final dynamic data;

  const Message({required this.type, required this.id, required this.time, this.data});

  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'time': time,
    if (data != null) 'data': data is Map ? data : (data as dynamic).toJson(),
  };
}

class ItemPushData {
  final String moduleType;
  final String content;
  const ItemPushData({required this.moduleType, required this.content});
  Map<String, dynamic> toJson() => {'module_type': moduleType, 'content': content};
}

class ItemBroadcastData {
  final String moduleType;
  final String content;
  final String deviceId;
  final String deviceName;
  final int seqNo;
  final int createdAt;
  const ItemBroadcastData({
    required this.moduleType, required this.content, required this.deviceId,
    required this.deviceName, required this.seqNo, required this.createdAt,
  });
  factory ItemBroadcastData.fromJson(Map<String, dynamic> j) => ItemBroadcastData(
    moduleType: j['module_type'], content: j['content'],
    deviceId: j['device_id'], deviceName: j['device_name'],
    seqNo: j['seq_no'], createdAt: j['created_at'],
  );
}

class PullHistoryData {
  final String moduleType;
  final int sinceSeqNo;
  const PullHistoryData({required this.moduleType, required this.sinceSeqNo});
  Map<String, dynamic> toJson() => {'module_type': moduleType, 'since_seq_no': sinceSeqNo};
}

class PullAckData {
  final String moduleType;
  final List<dynamic> items;
  const PullAckData({required this.moduleType, required this.items});
  factory PullAckData.fromJson(Map<String, dynamic> j) => PullAckData(
    moduleType: j['module_type'], items: j['items'] ?? [],
  );
}

class AckData {
  final String reqId;
  final int status;
  final String? detail;
  const AckData({required this.reqId, required this.status, this.detail});
  factory AckData.fromJson(Map<String, dynamic> j) => AckData(
    reqId: j['req_id'], status: j['status'], detail: j['detail'],
  );
}

class DeviceInfo {
  final String id;
  final String name;
  final String platform;
  final String role;
  final String status;
  final int lastSeen;
  const DeviceInfo({
    required this.id, required this.name, required this.platform,
    required this.role, required this.status, required this.lastSeen,
  });
  factory DeviceInfo.fromJson(Map<String, dynamic> j) => DeviceInfo(
    id: j['id'], name: j['name'], platform: j['platform'] ?? '',
    role: j['role'] ?? 'consumer', status: j['status'] ?? 'offline',
    lastSeen: j['last_seen'] ?? 0,
  );
}
