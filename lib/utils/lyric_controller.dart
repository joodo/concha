import 'package:flutter_lyric/flutter_lyric.dart';

extension LyricControllerHelpersExtension on LyricController {
  String? get lyricText {
    final model = lyricNotifier.value;
    if (model == null || model.lines.isEmpty) return null;

    return model.lines.join('\n');
  }

  String? get currentText {
    final model = lyricNotifier.value;
    if (model == null || model.lines.isEmpty) return null;

    final i = activeIndexNotifiter.value;
    if (i < 0 || i >= model.lines.length) return null;

    return model.lines[i].text;
  }
}
