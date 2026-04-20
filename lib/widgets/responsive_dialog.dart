import 'package:flutter/material.dart';

class ResponsiveDialog extends StatelessWidget {
  const ResponsiveDialog({super.key, this.widthThreshold, this.child});

  final double? widthThreshold;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fullscreen = width < (widthThreshold ?? 600.0);

    return Dialog(
      clipBehavior: .hardEdge,
      insetPadding: fullscreen ? EdgeInsets.zero : null,
      shape: fullscreen
          ? const RoundedRectangleBorder(borderRadius: BorderRadius.zero)
          : null,
      child: child,
    );
  }
}
