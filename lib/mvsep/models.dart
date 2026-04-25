import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

@JsonSerializable()
class MvsepJob {
  MvsepJob({required this.hash, required this.link});
  final String hash;
  final Uri link;

  factory MvsepJob.fromJson(Map<String, dynamic> json) =>
      _$MvsepJobFromJson(json);

  Map<String, dynamic> toJson() => _$MvsepJobToJson(this);
}
