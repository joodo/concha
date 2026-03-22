import 'package:flutter/material.dart';

extension WidgetExtension on String {
  Widget asText() => Text(this);
}

extension ShowSnackBarExtension on BuildContext {
  void showSnackBarText(String text) =>
      ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: text.asText()));
}

extension TooltipExtension on Widget {
  Widget tooltip(String message) => Tooltip(message: message, child: this);
}
