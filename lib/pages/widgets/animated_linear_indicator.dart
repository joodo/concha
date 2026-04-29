import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import '/utils/utils.dart';

class AnimatedLinearIndicator extends StatelessWidget {
  const AnimatedLinearIndicator({
    super.key,
    this.isRunning = true,
    this.progress,
  });
  final bool isRunning;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final indicator = progress != null
        ? TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress!),
            duration: 3.seconds,
            curve: Curves.easeInOutCubic,
            builder: (context, animatedValue, child) =>
                LinearProgressIndicator(value: animatedValue),
          )
        : LinearProgressIndicator();
    return indicator
        .constrained(
          height: progress != null || isRunning ? 4.0 : 0,
          animate: true,
        )
        .animate(150.milliseconds, Curves.linear);
  }
}
