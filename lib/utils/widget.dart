import 'package:flutter/material.dart';

extension WidgetExtension on String {
  Widget asText() => Text(this);
}

extension ShowSnackBarExtension on BuildContext {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    SnackBar snackbar,
  ) => ScaffoldMessenger.of(this).showSnackBar(snackbar);
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBarText(
    String text,
  ) => showSnackBar(SnackBar(content: text.asText()));
}

extension TooltipExtension on Widget {
  Widget tooltip(String message) => Tooltip(message: message, child: this);
}
