import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import '/utils/utils.dart';

class AnimatedLinearIndicator extends StatelessWidget {
  const AnimatedLinearIndicator({super.key, required this.isRunning});
  final bool? isRunning;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator()
        .constrained(height: isRunning ?? true ? 4.0 : 0, animate: true)
        .animate(150.milliseconds, Curves.linear);
  }
}
