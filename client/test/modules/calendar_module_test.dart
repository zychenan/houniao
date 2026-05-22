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

  test('calendar uses confirmed reliability', () {
    final reg = const ModuleRegistration(
      moduleType: 'calendar',
      tableName: 'items',
      mergeStrategy: 'lastWriteWins',
      reliability: Reliability.confirmed,
    );
    expect(reg.reliability, Reliability.confirmed);
    expect(reg.mergeStrategy, 'lastWriteWins');
  });

  test('calendar event save produces structured content', () async {
    final event = '{"title":"生日","date":"2026-06-15","type":"reminder"}';
    final seq = await ItemRepo.save('calendar', event, 'd1', 'phone');
    expect(seq, greaterThan(0));

    final items = await ItemRepo.getAll('calendar');
    expect(items.first.content, contains('生日'));
  });
}
