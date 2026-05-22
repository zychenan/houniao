import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:houniao/storage/database.dart';
import 'package:houniao/storage/item_repo.dart';
import 'package:houniao/core/sync_core.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await AppDatabase.close();
  });

  test('save note and retrieve', () async {
    final seq = await ItemRepo.save('notes', '第一条笔记', 'd1', 'phone');
    expect(seq, greaterThan(0));

    final items = await ItemRepo.getAll('notes');
    expect(items.length, 1);
    expect(items.first.content, '第一条笔记');
  });

  test('notes use atLeastOnce reliability', () {
    final reg = ModuleRegistration(
      moduleType: 'notes',
      tableName: 'items',
      mergeStrategy: 'manualResolve',
      reliability: Reliability.atLeastOnce,
    );
    expect(reg.reliability, Reliability.atLeastOnce);
    expect(reg.mergeStrategy, 'manualResolve');
  });
}
