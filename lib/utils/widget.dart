import 'package:flutter/material.dart';

extension WidgetExtension on String {
  Widget asText() => Text(this);
}

extension TooltipExtension on Widget {
  Widget tooltip(String message) => Tooltip(message: message, child: this);
}
