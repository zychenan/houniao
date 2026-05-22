import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:houniao/core/sync_core.dart';
import 'package:houniao/core/net_client.dart';
import 'package:houniao/core/sync_state.dart';

final netClientProvider = Provider<NetClient>((ref) => NetClient());

final syncCoreProvider = Provider<SyncCore>((ref) {
  final net = ref.watch(netClientProvider);
  return SyncCore(net, mode: NetworkMode.lanFirst);
});

final syncPhaseProvider = StreamProvider<SyncPhase>((ref) {
  final core = ref.watch(syncCoreProvider);
  return core.onPhaseChange;
});
