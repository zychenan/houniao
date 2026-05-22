// 复制此模板创建新模块：
// 1. 重命名类名为你的模块名
// 2. 设置 moduleType（唯一标识，如 'tasks'）
// 3. 选择 reliability 和 mergeStrategy
// 4. 在 app.dart 中注册并添加 Tab

import 'package:houniao/core/sync_core.dart';
import 'package:houniao/storage/item_repo.dart';
import 'package:houniao/protocol/message.dart';

class TemplateModule {
  static const moduleType = 'your_module_type'; // ← 改为唯一标识

  final SyncCore _core;

  TemplateModule(this._core) {
    _core.register(const ModuleRegistration(
      moduleType: moduleType,
      tableName: 'items',
      // mergeStrategy: lastWriteWins | manualResolve | appendOnly
      mergeStrategy: 'lastWriteWins',
      // reliability: bestEffort | atLeastOnce | confirmed
      reliability: Reliability.atLeastOnce,
    ), _onBroadcast);
  }

  void _onBroadcast(Message msg) {
    // 收到其他设备的广播时触发
  }

  Future<bool> push(String content) => _core.push(moduleType, content);

  Future<List<Item>> list({int limit = 50, int offset = 0}) =>
      ItemRepo.getAll(moduleType, limit: limit, offset: offset);

  Future<void> delete(int id) => ItemRepo.delete(id);
}
