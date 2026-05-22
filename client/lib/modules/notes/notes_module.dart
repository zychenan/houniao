import 'package:houniao/core/sync_core.dart';
import 'package:houniao/storage/item_repo.dart';
import 'package:houniao/protocol/message.dart';

class NotesModule {
  static const moduleType = 'notes';
  final SyncCore _core;

  NotesModule(this._core) {
    _core.register(const ModuleRegistration(
      moduleType: moduleType,
      tableName: 'items',
      mergeStrategy: 'manualResolve',
      reliability: Reliability.atLeastOnce,
    ), _onBroadcast);
  }

  void _onBroadcast(Message msg) {}

  Future<int> save(String content) async {
    final ok = await _core.push(moduleType, content);
    if (ok) {
      final items = await ItemRepo.getAll(moduleType, limit: 1);
      return items.isNotEmpty ? items.first.seqNo : -1;
    }
    return -1;
  }

  Future<List<Item>> list({int limit = 50, int offset = 0}) =>
      ItemRepo.getAll(moduleType, limit: limit, offset: offset);

  Future<void> delete(int id) => ItemRepo.delete(id);
}
