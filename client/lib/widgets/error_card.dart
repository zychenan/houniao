import 'package:flutter/material.dart';

class SyncError {
  final String problem;
  final String cause;
  final String action;
  final String suggestion;

  const SyncError({
    required this.problem,
    required this.cause,
    required this.action,
    required this.suggestion,
  });
}

class ErrorCard extends StatelessWidget {
  final SyncError error;

  const ErrorCard({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('问题：${error.problem}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('原因：${error.cause}'),
            const SizedBox(height: 4),
            Text('处理：${error.action}'),
            const SizedBox(height: 4),
            Text('建议：${error.suggestion}'),
          ],
        ),
      ),
    );
  }
}
