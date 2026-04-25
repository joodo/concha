// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MvsepJob _$MvsepJobFromJson(Map<String, dynamic> json) => MvsepJob(
  hash: json['hash'] as String,
  link: Uri.parse(json['link'] as String),
);

Map<String, dynamic> _$MvsepJobToJson(MvsepJob instance) => <String, dynamic>{
  'hash': instance.hash,
  'link': instance.link.toString(),
};
