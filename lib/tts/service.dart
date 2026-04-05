import 'dart:typed_data';

abstract class TtsService {
  Future<Uint8List> getVoice(
    String text, {
    required String prompt,
    dynamic apiKey,
    String? proxy,
  });
}
