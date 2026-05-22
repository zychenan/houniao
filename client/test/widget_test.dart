import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:houniao/app.dart';
import 'package:houniao/storage/database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await AppDatabase.close();
  });

  testWidgets('App loads home page', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: HouniaoApp()),
    );
    await tester.pumpAndSettle();
    // With an empty database, the app renders the tabbed interface.
    // The app title is "后鸟" per MaterialApp.title.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('剪贴板'), findsOneWidget);
    expect(find.text('笔记'), findsOneWidget);
    expect(find.text('日历'), findsOneWidget);
  });
}
