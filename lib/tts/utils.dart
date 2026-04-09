import 'dart:typed_data';

Uint8List convertToWavBytes(Uint8List audioBytes, {String? audioMimeType}) {
  final normalizedMimeType = audioMimeType?.toLowerCase() ?? '';
  if (normalizedMimeType.contains('wav')) {
    return audioBytes;
  }

  if (normalizedMimeType.isNotEmpty &&
      !normalizedMimeType.contains('pcm') &&
      !normalizedMimeType.contains('l16')) {
    throw Exception('语音生成失败：不支持的音频格式 $audioMimeType');
  }

  return _wrapPcm16ToWav(audioBytes, sampleRate: 24000, channels: 1);
}

Uint8List _wrapPcm16ToWav(
  Uint8List pcmBytes, {
  required int sampleRate,
  required int channels,
}) {
  const bitsPerSample = 16;
  final blockAlign = channels * (bitsPerSample ~/ 8);
  final byteRate = sampleRate * blockAlign;
  final dataLength = pcmBytes.lengthInBytes;
  final fileLength = 44 + dataLength;

  final wavBytes = Uint8List(fileLength);
  final header = ByteData.sublistView(wavBytes, 0, 44);

  _writeAscii(header, 0, 'RIFF');
  header.setUint32(4, 36 + dataLength, Endian.little);
  _writeAscii(header, 8, 'WAVE');
  _writeAscii(header, 12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, channels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);
  _writeAscii(header, 36, 'data');
  header.setUint32(40, dataLength, Endian.little);

  wavBytes.setRange(44, fileLength, pcmBytes);
  return wavBytes;
}

void _writeAscii(ByteData data, int offset, String text) {
  for (var i = 0; i < text.length; i++) {
    data.setUint8(offset + i, text.codeUnitAt(i));
  }
}
