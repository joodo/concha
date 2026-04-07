import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/projects/projects.dart';
import '/utils/utils.dart';

import 'riverpod.dart' hide LyricController;

extension LyricControllerExtension on WidgetRef {
  LyricController? get lyricController =>
      projectId.mapOrNull((v) => read(lyricControllerProvider(v)).value);
}
