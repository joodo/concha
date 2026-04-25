import 'dart:io';
import 'dart:typed_data';

Future<String?> detectAudioExtension(String filePath) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.openRead(0, 64)) {
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    if (bytes.isEmpty) return null;

    if (_startsWithAscii(bytes, 'ID3') || _looksLikeMp3FrameSync(bytes)) {
      return '.mp3';
    }
    if (_startsWithAscii(bytes, 'fLaC')) {
      return '.flac';
    }
    if (_startsWithAscii(bytes, 'OggS')) {
      return '.ogg';
    }
    if (_startsWithAscii(bytes, 'RIFF') && _containsAsciiAt(bytes, 'WAVE', 8)) {
      return '.wav';
    }
    if (_containsAsciiAt(bytes, 'ftyp', 4)) {
      return '.m4a';
    }
    if (_startsWithBytes(bytes, const <int>[0x1A, 0x45, 0xDF, 0xA3])) {
      return '.webm';
    }
    if (_looksLikeAacAdts(bytes)) {
      return '.aac';
    }
  } catch (_) {
    // Fall through to default extension.
  }

  return null;
}

bool _startsWithAscii(List<int> bytes, String text) {
  final chars = text.codeUnits;
  if (bytes.length < chars.length) {
    return false;
  }
  for (var i = 0; i < chars.length; i++) {
    if (bytes[i] != chars[i]) {
      return false;
    }
  }
  return true;
}

bool _looksLikeMp3FrameSync(List<int> bytes) {
  if (bytes.length < 2) {
    return false;
  }
  final first = bytes[0];
  final second = bytes[1];
  return first == 0xFF && (second & 0xE0) == 0xE0;
}

bool _containsAsciiAt(List<int> bytes, String text, int offset) {
  final chars = text.codeUnits;
  if (bytes.length < offset + chars.length) {
    return false;
  }
  for (var i = 0; i < chars.length; i++) {
    if (bytes[offset + i] != chars[i]) {
      return false;
    }
  }
  return true;
}

bool _startsWithBytes(List<int> bytes, List<int> signature) {
  if (bytes.length < signature.length) {
    return false;
  }
  for (var i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) {
      return false;
    }
  }
  return true;
}

bool _looksLikeAacAdts(List<int> bytes) {
  if (bytes.length < 2) {
    return false;
  }
  final first = bytes[0];
  final second = bytes[1];
  return first == 0xFF && (second & 0xF6) == 0xF0;
}
