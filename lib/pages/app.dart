import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/preferences/preferences.dart';
import '/utils/utils.dart';

import 'project/project_page.dart';
import 'start/start_page.dart';

class ConchaApp extends ConsumerWidget {
  const ConchaApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeString = ref.watch(preferenceProvider<String>(.brightness));
    final themeMode =
        ThemeMode.values.firstWhereOrNull((e) => e.name == themeModeString) ??
        ThemeMode.system;

    return MaterialApp(
      title: 'Concha',
      theme: _buildThemeData(.light),
      darkTheme: _buildThemeData(.dark),
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => StartPage(),
        '/project': (context) => ProjectPage(),
      },
    );
  }

  ThemeData _buildThemeData(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(0x00e9c299),
        brightness: brightness,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const SharedAxisPageTransitionsBuilder(
              transitionType: SharedAxisTransitionType.horizontal,
            ),
        },
      ),
    );
  }
}
