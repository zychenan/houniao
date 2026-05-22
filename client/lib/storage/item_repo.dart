import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'database.dart';

class Item {
  final int? id;
  final String moduleType;
  final String content;
  final String deviceId;
  final String deviceName;
  final String contentHash;
  final int createdAt;
  final int seqNo;

  const Item({
    this.id,
    required this.moduleType,
    required this.content,
    required this.deviceId,
    required this.deviceName,
    required this.contentHash,
    required this.createdAt,
    required this.seqNo,
  });

  Map<String, dynamic> toMap() => {
    'module_type': moduleType,
    'content': content,
    'device_id': deviceId,
    'device_name': deviceName,
    'content_hash': contentHash,
    'created_at': createdAt,
    'seq_no': seqNo,
  };

  factory Item.fromMap(Map<String, dynamic> m) => Item(
    id: m['id'] as int?,
    moduleType: m['module_type'] as String,
    content: m['content'] as String,
    deviceId: m['device_id'] as String,
    deviceName: m['device_name'] as String,
    contentHash: m['content_hash'] as String,
    createdAt: m['created_at'] as int,
    seqNo: m['seq_no'] as int,
  );
}

class ItemRepo {
  static String _hash(String content) =>
      sha256.convert(utf8.encode(content)).toString();

  static Future<int> save(
    String moduleType,
    String content,
    String deviceId,
    String deviceName,
  ) async {
    final db = await AppDatabase.instance;
    final hash = _hash(content);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check duplicate by hash + module_type
    final exists = await db.query('items',
      where: 'content_hash = ? AND module_type = ?',
      whereArgs: [hash, moduleType],
      limit: 1,
    );
    if (exists.isNotEmpty) return exists.first['seq_no'] as int;

    // Get max seq_no per module + 1
    final maxSeq = await db.rawQuery(
      'SELECT COALESCE(MAX(seq_no), 0) as m FROM items WHERE module_type = ?',
      [moduleType],
    );
    final seqNo = (maxSeq.first['m'] as int) + 1;

    await db.insert('items', {
      'module_type': moduleType,
      'content': content,
      'device_id': deviceId,
      'device_name': deviceName,
      'content_hash': hash,
      'created_at': now,
      'seq_no': seqNo,
    });
    return seqNo;
  }

  static Future<List<Item>> pullSince(String moduleType, int sinceSeqNo) async {
    final db = await AppDatabase.instance;
    final rows = await db.query('items',
      where: 'module_type = ? AND seq_no > ?',
      whereArgs: [moduleType, sinceSeqNo],
      orderBy: 'seq_no ASC',
      limit: 100,
    );
    return rows.map((r) => Item.fromMap(r)).toList();
  }

  static Future<int> lastSeqNo(String moduleType) async {
    final db = await AppDatabase.instance;
    final result = await db.rawQuery(
      'SELECT COALESCE(MAX(seq_no), 0) as m FROM items WHERE module_type = ?',
      [moduleType],
    );
    return result.first['m'] as int;
  }

  static Future<void> mergeIncoming(List<Item> items) async {
    final db = await AppDatabase.instance;
    final batch = db.batch();
    for (final item in items) {
      final exists = await db.query('items',
        where: 'content_hash = ? AND module_type = ?',
        whereArgs: [item.contentHash, item.moduleType],
        limit: 1,
      );
      if (exists.isEmpty) {
        batch.insert('items', item.toMap());
      }
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Item>> getAll(
    String moduleType, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await AppDatabase.instance;
    final rows = await db.query('items',
      where: 'module_type = ?',
      whereArgs: [moduleType],
      orderBy: 'seq_no DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map((r) => Item.fromMap(r)).toList();
  }

  static Future<void> delete(int id) async {
    final db = await AppDatabase.instance;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clean(String moduleType, int retentionDays) async {
    final db = await AppDatabase.instance;
    final cutoff = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    await db.delete('items',
      where: 'module_type = ? AND created_at < ?',
      whereArgs: [moduleType, cutoff],
    );
  }
}
