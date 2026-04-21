import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
abstract class Project with _$Project {
  static const Uuid _uuid = Uuid();

  Project._({String? id}) : id = id ?? _uuid.v4();

  factory Project({
    String? id,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration lyricOffset,
    String? summary,
    required Metadata metadata,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);

  @override
  final String id;

  static late String savedDir;
  static Future<void> initSavedDir() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final projectsDir = Directory('${appSupportDir.path}/projects/');
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }
    savedDir = projectsDir.path;
  }

  ProjectPath get path => ProjectPath(id);

  Future<void> save() async {
    final dir = Directory(path.dir);
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File(path.info);
    final data = jsonEncode(toJson());
    await file.writeAsString(data);
  }
}

@freezed
abstract class Metadata with _$Metadata {
  const factory Metadata({
    required String title,
    String? artist,
    String? album,
  }) = _Metadata;

  factory Metadata.fromJson(Map<String, dynamic> json) =>
      _$MetadataFromJson(json);

  const Metadata._();

  String get displayTitle {
    final suffix = artist == null ? '' : ' - $artist';
    return '$title$suffix';
  }
}

class ProjectPath {
  const ProjectPath(this.id);

  final String id;

  String get dir => '${Project.savedDir}/$id';

  String get info => '$dir/info.json';
  String get audio => '$dir/audio';
  String get audioVocals => '$dir/audio.vocals';
  String get audioInstru => '$dir/audio.inst';
  String get cover => '$dir/cover';
  String get lyric => '$dir/lyric';
  String get lyricT => '$dir/lyric.t';
}
