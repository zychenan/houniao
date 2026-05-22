import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houniao/widgets/error_card.dart';

void main() {
  testWidgets('renders all 4 fields', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ErrorCard(
          error: const SyncError(
            problem: '笔记同步失败',
            cause: '目标设备离线',
            action: '已放入离线队列',
            suggestion: '无需操作',
          ),
        ),
      ),
    ));
    expect(find.textContaining('笔记同步失败'), findsOneWidget);
    expect(find.textContaining('目标设备离线'), findsOneWidget);
    expect(find.textContaining('已放入离线队列'), findsOneWidget);
    expect(find.textContaining('无需操作'), findsOneWidget);
  });
}
