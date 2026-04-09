import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'project/project_page.dart';
import 'start/start_page.dart';

class ConchaApp extends HookWidget {
  const ConchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      final listener = AppLifecycleListener(onDetach: () => _deinitSoLoud());

      return () {
        listener.dispose();
        _deinitSoLoud();
      };
    }, const []);

    return MaterialApp(
      title: 'Concha',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0x00e9c299)),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final platform in TargetPlatform.values)
              platform: const SharedAxisPageTransitionsBuilder(
                transitionType: SharedAxisTransitionType.horizontal,
              ),
          },
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => StartPage(),
        '/project': (context) => ProjectPage(),
      },
    );
  }

  void _deinitSoLoud() {
    final soLoud = SoLoud.instance;
    if (soLoud.isInitialized) {
      soLoud.deinit();
    }
  }
}
