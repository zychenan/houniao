import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:houniao/storage/database.dart';
import 'package:houniao/storage/item_repo.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await AppDatabase.close();
  });

  test('save and pull since', () async {
    const mod = '_test_verify';
    final seq1 = await ItemRepo.save(mod, 'hello', 'd1', 'phone');
    expect(seq1, 1);

    final seq2 = await ItemRepo.save(mod, 'world', 'd2', 'pc');
    expect(seq2, 2);

    final items = await ItemRepo.pullSince(mod, 0);
    expect(items.length, 2);
    expect(items[0].content, 'hello');
    expect(items[1].content, 'world');
  });

  test('duplicate hash returns existing seq_no', () async {
    const mod = '_test_dup';
    final first = await ItemRepo.save(mod, 'dup', 'd1', 'p');
    final second = await ItemRepo.save(mod, 'dup', 'd2', 'q');
    expect(second, first);
  });

  test('lastSeqNo returns 0 for empty module', () async {
    final s = await ItemRepo.lastSeqNo('_test_empty_xyz');
    expect(s, 0);
  });
}
