import 'package:flutter/material.dart';

extension ButtonSizeExtension on ButtonStyle {
  ButtonStyle large(BuildContext context) => copyWith(
    minimumSize: const WidgetStatePropertyAll(Size(56.0, 56.0)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
    ),
    textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.titleMedium),
    iconSize: WidgetStatePropertyAll(24.0),
  );
}
