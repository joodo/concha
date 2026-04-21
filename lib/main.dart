import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/pages/app.dart';
import '/preferences/preferences.dart';
import '/projects/projects.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SoLoud.instance.init();

  await Pref.init();

  await Project.initSavedDir();

  runApp(ProviderScope(retry: (_, _) => null, child: ConchaApp()));
}
