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
    required this.audioPath,
    String? lyricPath,
    Duration position = Duration.zero,
  }) : id = id ?? _uuid.v4(),
       _lyricPath = lyricPath,
       _position = position;

  final String id;

  final String audioPath;

  @JsonKey(name: 'position')
  Duration _position;

  @JsonKey(name: 'lyricPath')
  String? _lyricPath;

  Duration get position => _position;
  set position(Duration value) {
    _position = value;
    unawaited(save());
  }

  String? get lyricPath => _lyricPath;
  set lyricPath(String? value) {
    _lyricPath = value;
    unawaited(save());
  }

  static Future<String> get savedDir async {
    final appSupportDir = await getApplicationSupportDirectory();
    final projectsDir = Directory('${appSupportDir.path}/projects');
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }
    return projectsDir.path;
  }

  static Future<Project> load(String id) async {
    final dirPath = await savedDir;
    final file = File('$dirPath/$id.json');
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return Project.fromJson(json);
  }

  Future<void> save() async {
    final dirPath = await savedDir;
    final file = File('$dirPath/$id.json');
    final data = jsonEncode(toJson());
    await file.writeAsString(data);
  }

  Future<void> delete() async {
    final dirPath = await savedDir;
    final file = File('$dirPath/$id.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectToJson(this);
}
