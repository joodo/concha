// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LrcLibLyric _$LrcLibLyricFromJson(Map<String, dynamic> json) => LrcLibLyric(
  trackName: json['trackName'] as String,
  artistName: LrcLibLyric._emptyIfNull(json['artistName'] as String?),
  albumName: LrcLibLyric._emptyIfNull(json['albumName'] as String?),
  duration: LrcLibLyric._durationFromDouble(
    (json['duration'] as num).toDouble(),
  ),
  plainLyrics: LrcLibLyric._emptyIfNull(json['plainLyrics'] as String?),
  syncedLyrics: LrcLibLyric._emptyIfNull(json['syncedLyrics'] as String?),
);

Map<String, dynamic> _$LrcLibLyricToJson(LrcLibLyric instance) =>
    <String, dynamic>{
      'trackName': instance.trackName,
      'artistName': instance.artistName,
      'albumName': instance.albumName,
      'plainLyrics': instance.plainLyrics,
      'syncedLyrics': instance.syncedLyrics,
      'duration': LrcLibLyric._durationToDouble(instance.duration),
    };
