import 'package:flutter/services.dart';

extension CopyToClipboardExtension on String {
  Future<void> copyToClipboard() =>
      Clipboard.setData(ClipboardData(text: this));
}
