import 'package:houniao/storage/database.dart';
import 'package:sqflite/sqflite.dart';

class SettingsStore {
  static Future<String?> get(String key) async {
    final db = await AppDatabase.instance;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  static Future<void> set(String key, String value) async {
    final db = await AppDatabase.instance;
    await db.insert('settings', {
      'key': key, 'value': value,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
