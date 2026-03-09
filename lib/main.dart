import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'pages/start/start_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final soLoud = SoLoud.instance;
  if (soLoud.isInitialized) {
    soLoud.deinit();
  }
  await soLoud.init();

  runApp(const ConchaApp());
}

class ConchaApp extends StatefulWidget {
  const ConchaApp({super.key});

  @override
  State<ConchaApp> createState() => _ConchaAppState();
}

class _ConchaAppState extends State<ConchaApp> {
  late final AppLifecycleListener _appLifecycleListener;

  @override
  void initState() {
    super.initState();
    _appLifecycleListener = AppLifecycleListener(onDetach: _deinitSoLoud);
  }

  @override
  void dispose() {
    _appLifecycleListener.dispose();
    _deinitSoLoud();
    super.dispose();
  }

  void _deinitSoLoud() {
    final soLoud = SoLoud.instance;
    if (soLoud.isInitialized) {
      soLoud.deinit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Concha',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final platform in TargetPlatform.values)
              platform: const SharedAxisPageTransitionsBuilder(
                transitionType: SharedAxisTransitionType.horizontal,
              ),
          },
        ),
      ),
      home: const StartPage(),
    );
  }
}
