import 'dart:convert';
import 'package:houniao/core/sync_core.dart';
import 'package:houniao/storage/item_repo.dart';
import 'package:houniao/protocol/message.dart';

class CalendarEvent {
  final String title;
  final String date; // YYYY-MM-DD
  final String type; // birthday | appointment | countdown | reminder
  final String? note;

  const CalendarEvent({
    required this.title,
    required this.date,
    required this.type,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date,
        'type': type,
        if (note != null) 'note': note,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> j) => CalendarEvent(
        title: j['title'] ?? '',
        date: j['date'] ?? '',
        type: j['type'] ?? '',
        note: j['note'] as String?,
      );
}

class CalendarModule {
  static const moduleType = 'calendar';
  final SyncCore _core;

  CalendarModule(this._core) {
    _core.register(
        const ModuleRegistration(
          moduleType: moduleType,
          tableName: 'items',
          mergeStrategy: 'lastWriteWins',
          reliability: Reliability.confirmed,
        ),
        _onBroadcast);
  }

  void _onBroadcast(Message msg) {}

  Future<bool> addEvent(CalendarEvent event) {
    return _core.push(moduleType, jsonEncode(event.toJson()));
  }

  Future<List<CalendarEvent>> getEvents(String date) async {
    final items = await ItemRepo.getAll(moduleType, limit: 200);
    return items
        .map((i) => CalendarEvent.fromJson(jsonDecode(i.content)))
        .where((e) => e.date == date)
        .toList();
  }
}
