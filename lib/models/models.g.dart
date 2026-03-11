// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project _$ProjectFromJson(Map<String, dynamic> json) => Project(
  id: json['id'] as String?,
  position: json['position'] == null
      ? Duration.zero
      : Duration(microseconds: (json['position'] as num).toInt()),
  metadata: Metadata.fromJson(json['metadata'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
  'id': instance.id,
  'metadata': instance.metadata,
  'position': instance.position.inMicroseconds,
};

Metadata _$MetadataFromJson(Map<String, dynamic> json) => Metadata(
  title: json['title'] as String,
  artist: json['artist'] as String?,
  album: json['album'] as String?,
);

Map<String, dynamic> _$MetadataToJson(Metadata instance) => <String, dynamic>{
  'title': instance.title,
  'artist': instance.artist,
  'album': instance.album,
};
