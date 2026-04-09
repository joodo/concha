import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'project/project_page.dart';
import 'start/start_page.dart';

class ConchaApp extends StatelessWidget {
  const ConchaApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeData = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Color(0x00e9c299)),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const SharedAxisPageTransitionsBuilder(
              transitionType: SharedAxisTransitionType.horizontal,
            ),
        },
      ),
    );

    return MaterialApp(
      title: 'Concha',
      theme: themeData,
      initialRoute: '/',
      routes: {
        '/': (context) => StartPage(),
        '/project': (context) => ProjectPage(),
      },
    );
  }
}
