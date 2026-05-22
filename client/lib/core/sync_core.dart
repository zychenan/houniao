import 'dart:async';
import 'package:houniao/core/sync_state.dart';
import 'package:houniao/core/net_client.dart';
import 'package:houniao/protocol/message.dart';
import 'package:houniao/storage/item_repo.dart';

enum Reliability { bestEffort, atLeastOnce, confirmed }

class ModuleRegistration {
  final String moduleType;
  final String tableName;
  final String mergeStrategy; // lastWriteWins | manualResolve | appendOnly
  final Reliability reliability;

  const ModuleRegistration({
    required this.moduleType,
    required this.tableName,
    required this.mergeStrategy,
    required this.reliability,
  });
}

class OfflineQueueEntry {
  final String moduleType;
  final String content;

  const OfflineQueueEntry({required this.moduleType, required this.content});
}

typedef MessageHandler = void Function(Message msg);

class SyncCore {
  final NetClient _net;
  final SyncStateMachine _state;
  final _modules = <String, ModuleRegistration>{};
  final _handlers = <String, MessageHandler>{};
  final _offlineQueue = <OfflineQueueEntry>[];
  final _stateController = StreamController<SyncPhase>.broadcast();
  String? _deviceId;
  String? _deviceName;

  SyncCore(this._net, {NetworkMode mode = NetworkMode.lanFirst})
      : _state = SyncStateMachine(networkMode: mode);

  SyncPhase get phase => _state.current;
  Stream<SyncPhase> get onPhaseChange => _stateController.stream;
  List<OfflineQueueEntry> get offlineQueue => List.unmodifiable(_offlineQueue);

  // --- Module registration ---

  void register(ModuleRegistration mod, MessageHandler handler) {
    _modules[mod.moduleType] = mod;
    _handlers[mod.moduleType] = handler;
  }

  // --- Connection ---

  Future<void> connect(String url, String deviceId, String deviceName) async {
    _deviceId = deviceId;
    _deviceName = deviceName;
    _state.transition(SyncEvent.networkUp);
    _stateController.add(_state.current);

    await _net.connect(url, deviceId, deviceName);
    _state.transition(SyncEvent.connected);
    _stateController.add(_state.current);

    _net.messages.listen(_onMessage);
    _net.onConnectionChange.listen((connected) {
      if (!connected) {
        _state.transition(SyncEvent.disconnected);
        _stateController.add(_state.current);
      }
    });

    // Pull history for all registered modules
    await _pullAllModules();
    _state.transition(SyncEvent.syncComplete);
    _stateController.add(_state.current);

    // Drain offline queue
    await _drainQueue();
  }

  Future<void> _pullAllModules() async {
    for (final mod in _modules.values) {
      final lastSeq = await ItemRepo.lastSeqNo(mod.moduleType);
      await _net.sendAndWait('pull_history', {
        'module_type': mod.moduleType,
        'since_seq_no': lastSeq,
      });
    }
  }

  void _onMessage(Message msg) {
    if (msg.type == 'item_broadcast') {
      final data = ItemBroadcastData.fromJson(msg.data as Map<String, dynamic>);
      ItemRepo.mergeIncoming([Item(
        moduleType: data.moduleType,
        content: data.content,
        deviceId: data.deviceId,
        deviceName: data.deviceName,
        contentHash: '', // mergeIncoming deduplicates by hash anyway
        createdAt: data.createdAt,
        seqNo: data.seqNo,
      )]);
      _handlers[data.moduleType]?.call(msg);
    } else if (msg.type == 'pull_ack') {
      final data = PullAckData.fromJson(msg.data as Map<String, dynamic>);
      final items = data.items.map((i) {
        final m = i as Map<String, dynamic>;
        return Item(
          moduleType: data.moduleType,
          content: m['content'] ?? '',
          deviceId: m['device_id'] ?? '',
          deviceName: m['device_name'] ?? '',
          contentHash: m['content_hash'] ?? '',
          createdAt: m['created_at'] ?? 0,
          seqNo: m['seq_no'] ?? 0,
        );
      }).toList();
      ItemRepo.mergeIncoming(items);
      _handlers[data.moduleType]?.call(msg);
    } else if (msg.type == 'device_list') {
      _checkMaintainerPresence(msg.data as List<dynamic>? ?? []);
    }
  }

  void _checkMaintainerPresence(List<dynamic> devices) {
    final hasMaintainer = devices.any((d) {
      final di = DeviceInfo.fromJson(d as Map<String, dynamic>);
      return di.role == 'maintainer' && di.status == 'online';
    });
    if (hasMaintainer) {
      _state.transition(SyncEvent.maintainerOnline);
    } else {
      _state.transition(SyncEvent.noMaintainer);
    }
    _stateController.add(_state.current);
  }

  // --- Push ---

  Future<bool> push(String moduleType, String content) async {
    final mod = _modules[moduleType];
    if (mod == null) return false;

    // Write locally first
    await ItemRepo.save(moduleType, content, _deviceId ?? 'local', _deviceName ?? '');

    // Send to server
    try {
      final ack = await _net.sendAndWait('item_push', {
        'module_type': moduleType,
        'content': content,
      });
      if (ack.status != 0 && mod.reliability != Reliability.bestEffort) {
        _enqueue(moduleType, content);
      }
      return ack.status == 0;
    } catch (_) {
      if (mod.reliability != Reliability.bestEffort) {
        _enqueue(moduleType, content);
      }
      return false;
    }
  }

  void _enqueue(String moduleType, String content) {
    _offlineQueue.add(OfflineQueueEntry(moduleType: moduleType, content: content));
  }

  Future<void> _drainQueue() async {
    while (_offlineQueue.isNotEmpty) {
      final entry = _offlineQueue.removeAt(0);
      await _net.sendAndWait('item_push', {
        'module_type': entry.moduleType,
        'content': entry.content,
      });
    }
  }

  void dispose() {
    _net.dispose();
    _stateController.close();
  }
}
