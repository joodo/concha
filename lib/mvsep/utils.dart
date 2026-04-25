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

String srtToLrc(String srt) {
  final lines = srt.split('\n');

  final buffer = <_Entry>[];
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();

    final timeMatch = RegExp(
      r'(\d{2}):(\d{2}):(\d{2}),(\d{3}) -->',
    ).firstMatch(line);

    if (timeMatch != null) {
      final textBuffer = StringBuffer();

      int j = i + 1;
      while (j < lines.length && lines[j].trim().isNotEmpty) {
        textBuffer.write(lines[j].trim());
        if (j + 1 < lines.length && lines[j + 1].trim().isNotEmpty) {
          textBuffer.write(' ');
        }
        j++;
      }

      final text = textBuffer.toString().trim();
      if (text.isEmpty) continue;

      final minutes = int.parse(timeMatch.group(2)!);
      final seconds = int.parse(timeMatch.group(3)!);
      final millis = int.parse(timeMatch.group(4)!);

      final lrcTime =
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}.'
          '${(millis ~/ 10).toString().padLeft(2, '0')}';

      buffer.add(_Entry(lrcTime, text));

      i = j;
    }
  }

  // Remove repeat
  final result = <_Entry>[];

  for (final entry in buffer) {
    if (result.isEmpty) {
      result.add(entry);
      continue;
    }

    final last = result.last;

    if (entry.text == last.text) continue;

    if (_similarity(entry.text, last.text) > 0.85) continue;

    result.add(entry);
  }

  return result.map((e) => '[${e.time}]${e.text}').join('\n');
}

class _Entry {
  final String time;
  final String text;

  _Entry(this.time, this.text);
}

double _similarity(String a, String b) {
  final dist = _levenshtein(a, b);
  final maxLen = a.length > b.length ? a.length : b.length;
  if (maxLen == 0) return 1.0;
  return 1.0 - dist / maxLen;
}

int _levenshtein(String s, String t) {
  final m = s.length;
  final n = t.length;

  final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));

  for (int i = 0; i <= m; i++) {
    dp[i][0] = i;
  }
  for (int j = 0; j <= n; j++) {
    dp[0][j] = j;
  }

  for (int i = 1; i <= m; i++) {
    for (int j = 1; j <= n; j++) {
      final cost = s[i - 1] == t[j - 1] ? 0 : 1;
      dp[i][j] = [
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  return dp[m][n];
}
