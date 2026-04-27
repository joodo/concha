import 'package:flutter/material.dart';

import '/play_controller/play_controller.dart';
import '/utils/utils.dart';

class PlayProgressBar extends StatelessWidget {
  const PlayProgressBar({super.key, required this.controller});

  final PlayController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.positionNotifier,
      builder: (context, position, child) {
        return Slider(
          year2023: false,
          max: controller.duration.inMilliseconds.toDouble(),
          value: position.inMilliseconds.toDouble(),
          onChanged: (value) => controller.seekTo(value.round().milliseconds),
        );
      },
    );
  }
}
