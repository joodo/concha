import 'dart:typed_data';

import 'service.impl.dart';

abstract class TtsService {
  factory TtsService.fromPref() = TtsServiceImpl.fromPref;

  Future<Uint8List> getVoice(String text, {String? prompt});
  Future<void> test();
}
