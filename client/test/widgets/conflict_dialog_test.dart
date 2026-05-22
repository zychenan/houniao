import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:houniao/widgets/conflict_dialog.dart';

void main() {
  testWidgets('shows 3 options', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (ctx) => TextButton(
          child: const Text('open'),
          onPressed: () => showConflictDialog(ctx,
            fileName: 'test.md',
            myTime: '14:32',
            remoteTime: '14:35',
            onKeepMine: () {},
            onKeepRemote: () {},
            onManualMerge: () {},
          ),
        )),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('test.md'), findsOneWidget);
    expect(find.textContaining('保留我的版本'), findsOneWidget);
    expect(find.textContaining('保留远程版本'), findsOneWidget);
    expect(find.textContaining('手动合并'), findsOneWidget);
  });
}
