import 'package:flutter/widgets.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:provider/provider.dart';

import '/models/models.dart';
import '/waveform/waveform_controller.dart';
import '/services/services.dart';

class ReadAloudPendingNotifier extends ValueNotifier<bool> {
  ReadAloudPendingNotifier() : super(false);
}

extension ProjectProvidersExtension on Widget {
  Widget projectProviders({required Project project}) => MultiProvider(
    providers: [
      Provider.value(value: project),
      Provider(
        create: (context) => PlayController(audioPath: project.path.audio),
        dispose: (context, value) => value.dispose(),
      ),
      Provider(
        create: (context) => WavefromController(),
        dispose: (context, value) => value.dispose(),
      ),
      Provider(
        create: (context) => LyricController(),
        dispose: (context, value) => value.dispose(),
      ),
      Provider(
        create: (context) => ReadAloudPendingNotifier(),
        dispose: (context, value) => value.dispose(),
      ),
    ],
    child: this,
  );
}
