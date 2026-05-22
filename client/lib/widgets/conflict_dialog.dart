import 'package:flutter/material.dart';

Future<void> showConflictDialog(
  BuildContext context, {
  required String fileName,
  required String myTime,
  required String remoteTime,
  required VoidCallback onKeepMine,
  required VoidCallback onKeepRemote,
  required VoidCallback onManualMerge,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('"$fileName" 已被其他设备更新'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('你的版本：最后修改 $myTime'),
          Text('远程版本：最后修改 $remoteTime'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onKeepMine();
          },
          child: const Text('保留我的版本'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onKeepRemote();
          },
          child: const Text('保留远程版本（推荐）'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onManualMerge();
          },
          child: const Text('手动合并'),
        ),
      ],
    ),
  );
}
