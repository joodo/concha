import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/pages/app.dart';
import '/preferences/preferences.dart';
import '/projects/models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final soLoud = SoLoud.instance;
  if (soLoud.isInitialized) {
    soLoud.deinit();
  }
  await soLoud.init();

  await Pref.init();

  await Project.initSavedDir();

  runApp(const ProviderScope(child: ConchaApp()));
}
