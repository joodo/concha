import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/generated/l10n.dart';
import '/preferences/preferences.dart';
import '/utils/utils.dart';

import 'lyric_editing/lyric_editing_page.dart';
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

    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Concha',

      // I18n
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      locale: locale,

      // Theme
      theme: _buildThemeData(.light),
      darkTheme: _buildThemeData(.dark),
      themeMode: themeMode,

      // Routing
      initialRoute: '/',
      routes: {
        '/': (context) => const StartPage(),
        '/project': (context) => const ProjectPage(),
        '/lyric': (context) => const LyricEditingPage(),
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
