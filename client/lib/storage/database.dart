import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  static Database? _db;
  static bool _initialized = false;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    if (!_initialized && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      databaseFactory = databaseFactoryFfi;
      _initialized = true;
    }
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'houniao.db'),
      version: 1,
      onCreate: _onCreate,
    );
    return _db!;
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        module_type TEXT NOT NULL DEFAULT 'clipboard',
        content TEXT NOT NULL,
        device_id TEXT NOT NULL,
        device_name TEXT NOT NULL DEFAULT '',
        content_hash TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        seq_no INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX idx_items_hash ON items (content_hash, module_type)',
    );
    await db.execute(
      'CREATE INDEX idx_items_module_seq ON items (module_type, seq_no)',
    );

    await db.execute('''
      CREATE TABLE devices (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        platform TEXT NOT NULL DEFAULT '',
        role TEXT NOT NULL DEFAULT 'consumer',
        ip TEXT NOT NULL DEFAULT '',
        port INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'offline',
        last_seen INTEGER NOT NULL DEFAULT 0,
        proto_ver INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_devices_status ON devices (status)',
    );

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL DEFAULT '',
        updated_at INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}
