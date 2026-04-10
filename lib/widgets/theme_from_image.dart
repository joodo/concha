import 'dart:io';

import 'package:flutter/material.dart';

import '/utils/utils.dart';

class ThemeFromImage extends StatelessWidget {
  const ThemeFromImage({super.key, required this.path, required this.child});
  final Widget child;
  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ColorScheme.fromImageProvider(
        provider: FileImage(File(path)),
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
