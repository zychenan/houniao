import 'package:houniao/core/sync_core.dart';
import 'package:houniao/storage/item_repo.dart';
import 'package:houniao/protocol/message.dart';
import 'clipboard_capture.dart';

class ClipboardModule {
  static const moduleType = 'clipboard';
  final SyncCore _core;
  final _capture = ClipboardCapture();

  ClipboardModule(this._core) {
    _core.register(const ModuleRegistration(
      moduleType: moduleType,
      tableName: 'items',
      mergeStrategy: 'appendOnly',
      reliability: Reliability.bestEffort,
    ), _onBroadcast);
  }

  void startCapturing() {
    _capture.startListening((content) {
      _core.push(moduleType, content);
    });
  }

  void _onBroadcast(Message msg) {
    // UI refresh driven by Riverpod provider
  }

  Future<List<Item>> getHistory({int limit = 50, int offset = 0}) =>
      ItemRepo.getAll(moduleType, limit: limit, offset: offset);

  Future<void> deleteItem(int id) => ItemRepo.delete(id);
}
