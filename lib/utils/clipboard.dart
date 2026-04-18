import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

extension CopyToClipboardExtension on String {
  Future<void> copyToClipboard() =>
      Clipboard.setData(ClipboardData(text: this));
}

extension ClipboardExtension on TextEditingController {
  Future<void> copySelectionToClipboard() =>
      selection.textInside(text).copyToClipboard();

  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;

    final newText = text.replaceRange(
      selection.start,
      selection.end,
      data!.text!,
    );
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + data.text!.length,
      ),
    );
  }
}
