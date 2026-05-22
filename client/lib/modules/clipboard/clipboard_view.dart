import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:houniao/storage/item_repo.dart';

class ClipboardView extends StatefulWidget {
  const ClipboardView({super.key});

  @override
  State<ClipboardView> createState() => _ClipboardViewState();
}

class _ClipboardViewState extends State<ClipboardView> {
  List<Item> _items = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await ItemRepo.getAll('clipboard');
    if (!mounted) return;
    if (_items.length != items.length ||
        items.isNotEmpty && items.first.createdAt != _items.firstOrNull?.createdAt) {
      setState(() => _items = items);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('等待同步… 复制一段文字试试',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (ctx, i) {
        final item = _items[i];
        return Card(
          child: ListTile(
            title: Text(item.content, maxLines: 3, overflow: TextOverflow.ellipsis),
            subtitle: Text('${item.deviceName} · ${_formatTime(item.createdAt)}'),
            onTap: () => Clipboard.setData(ClipboardData(text: item.content)),
          ),
        );
      },
    );
  }

  String _formatTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

extension on List<Item> {
  Item? get firstOrNull => isEmpty ? null : first;
}
