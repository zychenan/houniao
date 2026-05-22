import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:houniao/core/providers.dart';
import 'package:houniao/core/sync_state.dart';
import 'package:houniao/modules/clipboard/clipboard_view.dart';
import 'package:houniao/modules/notes/notes_view.dart';
import 'package:houniao/modules/calendar/calendar_view.dart';
import 'package:houniao/widgets/degraded_bar.dart';

class HouniaoApp extends ConsumerWidget {
  const HouniaoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(syncPhaseProvider).value ?? SyncPhase.offline;

    // ClipboardModule is created in build for simplicity in this initial version.
    // A production app would use a Provider to hold the module instance.

    return MaterialApp(
      title: '后鸟',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        body: Column(
          children: [
            SyncStatusBar(phase: phase.name),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          TabBar(tabs: [
            Tab(text: '剪贴板', icon: Icon(Icons.content_paste, size: 18)),
            Tab(text: '笔记', icon: Icon(Icons.note, size: 18)),
            Tab(text: '日历', icon: Icon(Icons.calendar_today, size: 18)),
          ]),
          Expanded(
            child: TabBarView(children: [
              ClipboardView(),
              NotesView(),
              CalendarView(),
            ]),
          ),
        ],
      ),
    );
  }
}
