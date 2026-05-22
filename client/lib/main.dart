import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:houniao/core/providers.dart';
import 'package:houniao/modules/clipboard/clipboard_module.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
  }
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  final container = ProviderContainer();
  final syncCore = container.read(syncCoreProvider);
  ClipboardModule(syncCore).startCapturing();

  final serverUrl = 'ws://10.247.143.198:9527/ws';
  final deviceId = Platform.isAndroid ? 'android-dev' : 'windows-dev';
  final deviceName = Platform.isAndroid ? 'Android' : 'Windows Dev';
  syncCore.connect(serverUrl, deviceId, deviceName);

  runApp(ProviderScope(parent: container, child: const HouniaoApp()));
}
