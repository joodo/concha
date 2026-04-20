// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Project _$ProjectFromJson(Map<String, dynamic> json) => _Project(
  id: json['id'] as String?,
  position: json['position'] == null
      ? Duration.zero
      : Duration(microseconds: (json['position'] as num).toInt()),
  lyricOffset: json['lyricOffset'] == null
      ? Duration.zero
      : Duration(microseconds: (json['lyricOffset'] as num).toInt()),
  summary: json['summary'] as String?,
  metadata: Metadata.fromJson(json['metadata'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProjectToJson(_Project instance) => <String, dynamic>{
  'id': instance.id,
  'position': instance.position.inMicroseconds,
  'lyricOffset': instance.lyricOffset.inMicroseconds,
  'summary': instance.summary,
  'metadata': instance.metadata,
};

_Metadata _$MetadataFromJson(Map<String, dynamic> json) => _Metadata(
  title: json['title'] as String,
  artist: json['artist'] as String?,
  album: json['album'] as String?,
);

Map<String, dynamic> _$MetadataToJson(_Metadata instance) => <String, dynamic>{
  'title': instance.title,
  'artist': instance.artist,
  'album': instance.album,
};
