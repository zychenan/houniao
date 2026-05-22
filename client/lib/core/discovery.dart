import 'package:houniao/storage/database.dart';
import 'package:sqflite/sqflite.dart';

class DiscoveredDevice {
  final String id;
  final String name;
  final String host;
  final int port;

  const DiscoveredDevice({
    required this.id, required this.name,
    required this.host, required this.port,
  });

  String get wsUrl => 'ws://$host:$port/ws';
}

class DiscoveryService {
  static Future<void> addManual(String id, String name, String host, int port) async {
    final db = await AppDatabase.instance;
    await db.insert('devices', {
      'id': id,
      'name': name,
      'platform': '',
      'role': 'consumer',
      'ip': host,
      'port': port,
      'status': 'online',
      'last_seen': DateTime.now().millisecondsSinceEpoch,
      'proto_ver': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<DiscoveredDevice>> knownDevices() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('devices', where: 'status != ?', whereArgs: ['offline']);
    return rows.map((r) => DiscoveredDevice(
      id: r['id'] as String,
      name: r['name'] as String,
      host: r['ip'] as String,
      port: r['port'] as int,
    )).toList();
  }
}
