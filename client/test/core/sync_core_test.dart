import 'package:flutter_test/flutter_test.dart';
import 'package:houniao/core/sync_core.dart';
import 'package:houniao/core/sync_state.dart';

void main() {
  test('ModuleRegistration creates correctly', () {
    final mod = ModuleRegistration(
      moduleType: 'clipboard',
      tableName: 'items',
      mergeStrategy: 'appendOnly',
      reliability: Reliability.bestEffort,
    );
    expect(mod.moduleType, 'clipboard');
    expect(mod.reliability, Reliability.bestEffort);
  });

  test('SyncCore initial phase is offline', () {
    // Note: Can't fully test SyncCore without NetClient,
    // but we can verify the state machine integration
    final sm = SyncStateMachine(networkMode: NetworkMode.lanFirst);
    expect(sm.current, SyncPhase.offline);
  });
}
