import 'package:flutter/material.dart';
import 'package:houniao/storage/item_repo.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ItemRepo.getAll('notes');
    setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Center(child: Text('还没有笔记'));
    }
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (ctx, i) {
        final item = _items[i];
        return ListTile(
          title: Text(item.content, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(item.deviceName),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () async {
              if (item.id != null) {
                await ItemRepo.delete(item.id!);
                await _load();
              }
            },
          ),
        );
      },
    );
  }
}
