import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/services/services.dart';
import '/utils/utils.dart';

import 'riverpod.dart';

class ProjectBusiness extends ConsumerStatefulWidget {
  const ProjectBusiness({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ProjectBusiness> createState() => _ProjectBusinessState();
}

class _ProjectBusinessState extends ConsumerState<ProjectBusiness> {
  PlayController get _playController => ref.playController!;

  @override
  void initState() {
    super.initState();

    runAfterBuild(() {
      _loadSeparatedAudio();
      _createSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _loadSeparatedAudio() {
    ref.listenManual(sepAudioEventProvider(ref.projectId!), (
      previous,
      next,
    ) async {
      if (next.hasError) {
        debugPrint('Failed to load sep audio: ${next.error}');
      }
      if (!next.hasValue) return;

      final event = next.value!;
      if (event is MvsepCompletedEvent) {
        await _playController.setSeparatedAudio(
          event.vocalPath,
          event.instruPath,
        );
        await _playController.setSeparateMode(true);
      }
    });
  }

  Future<void> _createSummary() async {
    if (ref.project?.summary?.isNotEmpty == true) return;
    return ref.projectNotifier!.generateSummary();
  }
}

extension ProjectBusinessExtension on Widget {
  Widget projectBusiness() => ProjectBusiness(child: this);
}
