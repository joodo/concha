import 'package:json_annotation/json_annotation.dart';

import '/utils/utils.dart';

part 'models.g.dart';

@JsonSerializable()
class LrcLibLyric {
  LrcLibLyric({
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.duration,
    required this.plainLyrics,
    required this.syncedLyrics,
  });

  final String trackName;
  @JsonKey(fromJson: _emptyIfNull)
  final String artistName;
  @JsonKey(fromJson: _emptyIfNull)
  final String albumName;
  @JsonKey(fromJson: _emptyIfNull)
  final String plainLyrics;
  @JsonKey(fromJson: _emptyIfNull)
  final String syncedLyrics;

  @JsonKey(fromJson: _durationFromDouble, toJson: _durationToDouble)
  final Duration duration;

  factory LrcLibLyric.fromJson(Map<String, dynamic> json) =>
      _$LrcLibLyricFromJson(json);

  Map<String, dynamic> toJson() => _$LrcLibLyricToJson(this);

  static Duration _durationFromDouble(double seconds) {
    return (seconds * 1000).round().milliseconds;
  }

  static double _durationToDouble(Duration duration) =>
      duration.inMilliseconds / 1000;

  static String _emptyIfNull(String? value) => value ?? '';
}
