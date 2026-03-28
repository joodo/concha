import 'package:flutter/material.dart';

import 'widget.dart';

extension BuildContextExtension on BuildContext {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    SnackBar snackbar, {
    bool clear = true,
  }) {
    final messager = ScaffoldMessenger.of(this);
    if (clear) messager.clearSnackBars();
    return ScaffoldMessenger.of(this).showSnackBar(snackbar);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBarText(
    String text, {
    bool clear = true,
  }) => showSnackBar(SnackBar(content: text.asText()), clear: clear);

  ColorScheme get colors => Theme.of(this).colorScheme;
}
