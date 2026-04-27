import 'package:flutter/material.dart';

import '/play_controller/play_controller.dart';
import '/utils/utils.dart';

class PlayProgressLabel extends StatelessWidget {
  const PlayProgressLabel({super.key, required this.controller});
  final PlayController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.positionNotifier,
      builder: (context, child) => Text(
        '${_formatDuration(controller.positionNotifier.value)} / ${_formatDuration(controller.duration)}',
        style: context.textStyles.titleMedium,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }
}
