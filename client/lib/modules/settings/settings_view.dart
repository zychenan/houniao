import 'package:flutter/material.dart';
import 'package:houniao/modules/settings/settings_module.dart';
import 'package:houniao/core/data_export.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _hostCtrl.text = await SettingsStore.get('server_host') ?? '100.65.8.60';
    _portCtrl.text = await SettingsStore.get('server_port') ?? '9527';
    _nameCtrl.text = await SettingsStore.get('device_name') ?? '';
    setState(() {});
  }

  Future<void> _save() async {
    await SettingsStore.set('server_host', _hostCtrl.text);
    await SettingsStore.set('server_port', _portCtrl.text);
    await SettingsStore.set('device_name', _nameCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存')),
      );
    }
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(controller: _hostCtrl, decoration: const InputDecoration(labelText: '服务器地址')),
        const SizedBox(height: 12),
        TextField(controller: _portCtrl, decoration: const InputDecoration(labelText: '端口')),
        const SizedBox(height: 12),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '设备名称')),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _save, child: const Text('保存')),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () async {
            final path = await DataExporter.exportToJson('clipboard');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导出到 $path')));
            }
          },
          icon: const Icon(Icons.download),
          label: const Text('导出剪贴板数据'),
        ),
      ],
    );
  }
}
