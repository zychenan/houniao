import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houniao/widgets/degraded_bar.dart';

void main() {
  testWidgets('shows yellow bar in degraded mode', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SyncStatusBar(phase: 'degraded')),
    ));
    expect(find.textContaining('部分功能受限'), findsOneWidget);
  });

  testWidgets('shows red bar in paused mode', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SyncStatusBar(phase: 'paused')),
    ));
    expect(find.textContaining('同步已暂停'), findsOneWidget);
  });

  testWidgets('shows nothing in ready mode', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SyncStatusBar(phase: 'ready')),
    ));
    expect(find.byIcon(Icons.warning_amber), findsNothing);
    expect(find.byIcon(Icons.cloud_off), findsNothing);
  });
}
