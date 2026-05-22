enum NetworkMode { lanFirst, serverOnly }

enum SyncPhase { offline, connecting, syncing, ready, degraded, paused }

enum SyncEvent {
  networkUp,
  networkDown,
  connected,
  disconnected,
  syncComplete,
  noMaintainer,
  maintainerOnline,
  serverUnreachable,
}

class SyncStateMachine {
  SyncPhase _current = SyncPhase.offline;
  final NetworkMode networkMode;

  SyncStateMachine({required this.networkMode});

  SyncPhase get current => _current;

  void transition(SyncEvent event) {
    _current = _next(_current, event, networkMode);
  }

  static SyncPhase _next(SyncPhase s, SyncEvent e, NetworkMode mode) {
    switch (s) {
      case SyncPhase.offline:
        if (e == SyncEvent.networkUp) return SyncPhase.connecting;
        return s;
      case SyncPhase.connecting:
        if (e == SyncEvent.networkDown) return SyncPhase.offline;
        if (e == SyncEvent.connected) return SyncPhase.syncing;
        if (e == SyncEvent.serverUnreachable && mode == NetworkMode.serverOnly)
          return SyncPhase.paused;
        return s;
      case SyncPhase.syncing:
        if (e == SyncEvent.networkDown) return SyncPhase.offline;
        if (e == SyncEvent.disconnected) return SyncPhase.connecting;
        if (e == SyncEvent.syncComplete) return SyncPhase.ready;
        if (e == SyncEvent.noMaintainer && mode == NetworkMode.lanFirst)
          return SyncPhase.degraded;
        return s;
      case SyncPhase.ready:
        if (e == SyncEvent.networkDown) return SyncPhase.offline;
        if (e == SyncEvent.disconnected) return SyncPhase.connecting;
        if (e == SyncEvent.noMaintainer && mode == NetworkMode.lanFirst)
          return SyncPhase.degraded;
        return s;
      case SyncPhase.degraded:
        if (e == SyncEvent.networkDown) return SyncPhase.offline;
        if (e == SyncEvent.maintainerOnline) return SyncPhase.syncing;
        return s;
      case SyncPhase.paused:
        if (e == SyncEvent.networkDown) return SyncPhase.offline;
        if (e == SyncEvent.connected) return SyncPhase.syncing;
        return s;
    }
  }
}
