import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
    required this.metadata,
  }) : id = id ?? _uuid.v4(),
       _position = position;

  final String id;
  final Metadata metadata;

  @JsonKey(name: 'position')
  Duration _position;

  Duration get position => _position;
  set position(Duration value) {
    _position = value;
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

  String get projectDirPath => '$savedDir/$id';
  String get audioPath => '$projectDirPath/audio';
  String get lyricPath => '$projectDirPath/lyric';
  String get lyricTPath => '$projectDirPath/lyric.t';

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
    final dir = Directory(projectDirPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File('$projectDirPath/info.json');
    final data = jsonEncode(toJson());
    await file.writeAsString(data);
  }

  Future<void> delete() async {
    final projectDir = Directory(projectDirPath);
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
  Metadata({required this.title, this.artist, this.album, this.coverBytes});

  final String title;
  final String? artist;
  final String? album;

  @JsonKey(fromJson: _coverBytesFromJson, toJson: _coverBytesToJson)
  final Uint8List? coverBytes;

  static Uint8List? _coverBytesFromJson(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return base64Decode(value);
  }

  static String? _coverBytesToJson(Uint8List? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return base64Encode(value);
  }

  factory Metadata.fromJson(Map<String, dynamic> json) =>
      _$MetadataFromJson(json);

  Map<String, dynamic> toJson() => _$MetadataToJson(this);
}
