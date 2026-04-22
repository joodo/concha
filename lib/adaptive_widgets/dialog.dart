import 'package:flutter/material.dart';

class AdaptiveDialog extends StatelessWidget {
  const AdaptiveDialog({
    super.key,
    required this.isFullscreen,
    this.child,
    this.backgroundColor,
  });

  final bool isFullscreen;
  final Color? backgroundColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: .hardEdge,
      insetPadding: isFullscreen ? EdgeInsets.zero : null,
      shape: isFullscreen
          ? const RoundedRectangleBorder(borderRadius: BorderRadius.zero)
          : null,
      backgroundColor: backgroundColor,
      child: child,
    );
  }
}
