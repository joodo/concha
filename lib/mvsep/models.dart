import 'package:json_annotation/json_annotation.dart';

import '/utils/utils.dart';

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

sealed class MvsepResult {
  const MvsepResult({required this.data});
  final JsonMap data;
}

class MvsepSeparationResult extends MvsepResult {
  const MvsepSeparationResult({required super.data});

  Uri get vocalUrl => _extractUriFromData('vocal');
  Uri get instrumentUrl => _extractUriFromData('other');

  Uri _extractUriFromData(String containedType) {
    final files = data['files'] as List;
    final url =
        files.firstWhere((file) {
              final type = file['type'] as String;
              return type.toLowerCase().contains(containedType);
            })['url']
            as String;
    return Uri.parse(url);
  }
}

sealed class MvsepJobStatus {
  const MvsepJobStatus({this.message});
  final String? message;
}

class MvsepJobStatusWaiting extends MvsepJobStatus {
  const MvsepJobStatusWaiting({
    required this.queueCount,
    required this.currentOrder,
    super.message,
  });
  final int queueCount, currentOrder;
}

class MvsepJobStatusProcessing extends MvsepJobStatus {
  MvsepJobStatusProcessing({super.message});
}

class MvsepJobStatusDone extends MvsepJobStatus {
  MvsepJobStatusDone({super.message});
}
