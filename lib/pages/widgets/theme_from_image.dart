import 'dart:typed_data';

import 'package:flutter/material.dart';

import '/utils/utils.dart';

class ThemeFromImage extends StatelessWidget {
  const ThemeFromImage({super.key, required this.data, required this.child});
  final Widget child;
  final Uint8List? data;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ColorScheme.fromImageProvider(
        provider: MemoryImage(data ?? Uint8List(0)),
        brightness: context.theme.brightness,
      ),
      initialData: context.colors,
      builder: (context, snapshot) => Theme(
        data: context.theme.copyWith(colorScheme: snapshot.data),
        child: child,
      ),
    );
  }
}
