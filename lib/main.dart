import 'package:concha/pages/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'models/models.dart';
import 'utils/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final soLoud = SoLoud.instance;
  if (soLoud.isInitialized) {
    soLoud.deinit();
  }
  await soLoud.init();

  await Pref.init();

  await Project.initSavedDir();

  runApp(const ConchaApp());
}
