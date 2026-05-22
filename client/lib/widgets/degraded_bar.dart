import 'package:flutter/material.dart';

class SyncStatusBar extends StatelessWidget {
  final String phase;

  const SyncStatusBar({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    if (phase == 'degraded') {
      return Container(
        width: double.infinity,
        color: Colors.amber.shade700,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '无维护设备在线 — 部分功能受限',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    if (phase == 'paused') {
      return Container(
        width: double.infinity,
        color: Colors.red.shade700,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: const Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '安全模式：服务器不可达，同步已暂停',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
