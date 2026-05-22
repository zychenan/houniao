import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardCapture {
  String _lastContent = '';
  Timer? _timer;

  void startListening(void Function(String) onCopy) {
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      Clipboard.getData(Clipboard.kTextPlain).then((data) {
        final text = data?.text?.trim() ?? '';
        if (text.isEmpty || text == _lastContent || text.length > 10000) return;
        _lastContent = text;
        onCopy(text);
      });
    });
  }

  void stopListening() {
    _timer?.cancel();
    _timer = null;
  }
}
