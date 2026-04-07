import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/projects/projects.dart';
import '/utils/utils.dart';

import 'riverpod.dart';
import 'service.dart';

extension PlayControllerExtension on WidgetRef {
  PlayController? get playController =>
      projectId.mapOrNull((v) => read(playControllerProvider(v)).value);
}
