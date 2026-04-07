import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/utils/utils.dart';

import 'models.dart';
import 'riverpod.dart';

extension ProjectExtension on WidgetRef {
  String? get projectId => context.routeArguments['id'];

  ProjectDetail? get projectNotifier =>
      projectId.mapOrNull((v) => read(projectDetailProvider(v).notifier));
  ProjectDetailProvider? get projectProvider =>
      projectId.mapOrNull((v) => projectDetailProvider(v));
  Project? get project =>
      projectId.mapOrNull((v) => read(projectDetailProvider(v)).value);
}
