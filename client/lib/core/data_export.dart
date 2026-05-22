import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:houniao/storage/database.dart';

class DataExporter {
  static Future<String> exportToJson(String moduleType) async {
    final db = await AppDatabase.instance;
    final rows = await db.query('items',
      where: 'module_type = ?',
      whereArgs: [moduleType],
      orderBy: 'seq_no ASC',
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'houniao_${moduleType}_export.json'));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(rows));
    return file.path;
  }
}
