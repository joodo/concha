import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'models.g.dart';

@JsonSerializable()
class Project {
  static const Uuid _uuid = Uuid();

  Project({
    String? id,
    Duration position = Duration.zero,
    Duration lyricOffset = Duration.zero,
    required this.metadata,
  }) : id = id ?? _uuid.v4(),
       _position = position,
       _lyricOffset = lyricOffset;

  final String id;
  final Metadata metadata;

  @JsonKey(name: 'position')
  Duration _position;
  Duration get position => _position;
  set position(Duration value) {
    _position = value;
    unawaited(save());
  }

  @JsonKey(name: 'lyricOffset')
  Duration _lyricOffset;
  Duration get lyricOffset => _lyricOffset;
  set lyricOffset(Duration value) {
    _lyricOffset = value;
    unawaited(save());
  }

  static late String savedDir;
  static Future<void> initSavedDir() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final projectsDir = Directory('${appSupportDir.path}/projects/');
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }
    savedDir = projectsDir.path;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  late final path = ProjectPath('$savedDir/$id');

  static Future<Project?> load(String id) async {
    try {
      final file = File('$savedDir/$id/info.json');
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return Project.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<void> save() async {
    final dir = Directory(path.dir);
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File('${path.dir}/info.json');
    final data = jsonEncode(toJson());
    await file.writeAsString(data);
  }

  Future<void> delete() async {
    final projectDir = Directory(path.dir);
    if (await projectDir.exists()) {
      await projectDir.delete(recursive: true);
    }
  }

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectToJson(this);
}

@JsonSerializable()
class Metadata {
  Metadata({required this.title, this.artist, this.album});

  final String title;
  final String? artist;
  final String? album;

  factory Metadata.fromJson(Map<String, dynamic> json) =>
      _$MetadataFromJson(json);

  Map<String, dynamic> toJson() => _$MetadataToJson(this);
}

class ProjectPath {
  const ProjectPath(this.dir);

  final String dir;

  String get audio => '$dir/audio';
  String get cover => '$dir/cover';
  String get lyric => '$dir/lyric';
  String get lyricT => '$dir/lyric.t';
}
