import 'package:flutter_test/flutter_test.dart';
import 'package:houniao/core/sync_state.dart';

void main() {
  test('initial state is offline', () {
    final s = SyncStateMachine(networkMode: NetworkMode.lanFirst);
    expect(s.current, SyncPhase.offline);
  });

  test('offline -> connecting -> syncing -> ready', () {
    final s = SyncStateMachine(networkMode: NetworkMode.lanFirst);
    s.transition(SyncEvent.networkUp);
    expect(s.current, SyncPhase.connecting);
    s.transition(SyncEvent.connected);
    expect(s.current, SyncPhase.syncing);
    s.transition(SyncEvent.syncComplete);
    expect(s.current, SyncPhase.ready);
  });

  test('lanFirst: no maintainer -> degraded', () {
    final s = SyncStateMachine(networkMode: NetworkMode.lanFirst);
    s.transition(SyncEvent.networkUp);
    s.transition(SyncEvent.connected);
    s.transition(SyncEvent.noMaintainer);
    expect(s.current, SyncPhase.degraded);
  });

  test('serverOnly: server unreachable -> paused', () {
    final s = SyncStateMachine(networkMode: NetworkMode.serverOnly);
    s.transition(SyncEvent.networkUp);
    s.transition(SyncEvent.serverUnreachable);
    expect(s.current, SyncPhase.paused);
  });

  test('degraded -> ready when maintainer appears', () {
    final s = SyncStateMachine(networkMode: NetworkMode.lanFirst);
    s.transition(SyncEvent.networkUp);
    s.transition(SyncEvent.connected);
    s.transition(SyncEvent.noMaintainer);
    expect(s.current, SyncPhase.degraded);
    s.transition(SyncEvent.maintainerOnline);
    expect(s.current, SyncPhase.syncing);
  });
}
