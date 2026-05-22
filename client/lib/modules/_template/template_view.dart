import 'package:flutter/material.dart';
import 'package:houniao/storage/item_repo.dart';

class TemplateView extends StatefulWidget {
  final String moduleType; // ← 替换为你的 moduleType
  final String emptyText;  // ← 替换为你的空状态文案

  const TemplateView({
    super.key,
    required this.moduleType,
    this.emptyText = '还没有数据',
  });

  @override
  State<TemplateView> createState() => _TemplateViewState();
}

class _TemplateViewState extends State<TemplateView> {
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ItemRepo.getAll(widget.moduleType);
    setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Center(child: Text(widget.emptyText));
    }
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (ctx, i) => ListTile(
        title: Text(_items[i].content,
            maxLines: 3, overflow: TextOverflow.ellipsis),
        subtitle: Text(_items[i].deviceName),
      ),
    );
  }
}
