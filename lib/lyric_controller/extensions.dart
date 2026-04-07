import 'package:flutter_lyric/core/lyric_model.dart';
import 'package:flutter_lyric/core/lyric_parse.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/projects/projects.dart';
import '/utils/utils.dart';

import 'riverpod.dart' hide LyricController;

extension LyricControllerExtension on WidgetRef {
  LyricController? get lyricController =>
      projectId.mapOrNull((v) => read(lyricControllerProvider(v)).value);
}

extension MultiLineLyricExtension on LyricController {
  static const lineSeparator = '\$\$\$';
  void loadMultiLineLyric(String lyric, {String? translationLyric}) {
    final lyricModel = LyricParse.parse(
      lyric,
      translationLyric: translationLyric,
    );
    final lines = lyricModel.lines
        .map(
          (e) => LyricLine(
            start: e.start,
            end: e.end,
            text: e.text.split(lineSeparator).map((e) => e.trim()).join('\n'),
            translation: e.translation
                ?.split(lineSeparator)
                .map((e) => e.trim())
                .join('\n'),
            words: e.words,
          ),
        )
        .toList();
    final newModel = lyricModel.copyWith(null, lines);
    return loadLyricModel(newModel);
  }
}
