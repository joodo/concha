import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:styled_widget/styled_widget.dart';

import '/pages/widgets/play_progress_bar.dart';
import '/pages/widgets/play_progress_label.dart';
import '/play_controller/play_controller.dart';
import '/utils/utils.dart';

import '../widgets/expansible_button.dart';

class PlaybackBar extends HookWidget {
  const PlaybackBar({super.key, required this.controller});

  final PlayController controller;

  @override
  Widget build(BuildContext context) {
    final toggleAnimation = useAnimationController(duration: 150.milliseconds);
    useEffect(() {
      void updatePlayback() {
        if (controller.isPlayNotifier.value) {
          toggleAnimation.forward();
        } else {
          toggleAnimation.reverse();
        }
      }

      controller.isPlayNotifier.addListener(updatePlayback);
      updatePlayback();

      return () => controller.isPlayNotifier.removeListener(updatePlayback);
    }, []);

    return BottomAppBar(
      color: context.colors.surfaceContainerLow,
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
      child: [
        IconButton.filled(
          icon: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            size: 36.0,
            progress: toggleAnimation,
          ),
          padding: const EdgeInsets.all(8.0),
          onPressed: controller.togglePlayPause,
        ),
        12.0.asWidth(),

        ValueListenableBuilder(
          valueListenable: controller.volumeNotifier,
          builder: (context, volume, child) => ExpansibleButton(
            isExpanded: false,
            icon: Icon(switch (volume) {
              > 0.5 => Icons.volume_up,
              > 0 => Icons.volume_down,
              _ => Icons.volume_mute,
            }, color: Theme.of(context).colorScheme.onSurfaceVariant),
            value: volume,
            labelStringBuilder: (value) => '${(value * 100).round()} %',
            divisions: 100,
            onChanged: controller.setVolume,
          ),
        ),
        PlayProgressBar(controller: controller).flexible(),
        PlayProgressLabel(controller: controller),
      ].toRow(),
    );
  }
}
