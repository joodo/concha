import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '/utils/utils.dart';

class PopupWidget extends HookWidget {
  const PopupWidget({
    super.key,
    this.child,
    this.showing = false,
    this.layoutBuilder,
    required this.popupBuilder,
  });

  final bool showing;
  final Widget Function(BuildContext context, Widget popup)? layoutBuilder;
  final WidgetBuilder popupBuilder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 75),
    );

    final portalController = useOverlayPortalController();
    useEffect(() {
      if (showing) {
        runAfterBuild(portalController.show);
        animationController.forward();
      } else {
        animationController.reverse().then((_) => portalController.hide());
      }
      return null;
    }, [showing]);

    return OverlayPortal(
      controller: portalController,
      overlayChildBuilder: (context) => AnimatedBuilder(
        animation: animationController,
        builder: (BuildContext context, Widget? child) {
          final animatedChild = FadeScaleTransition(
            animation: animationController,
            child: child,
          );

          if (layoutBuilder != null) {
            return layoutBuilder!(context, animatedChild);
          } else {
            return Center(child: animatedChild);
          }
        },
        child: Builder(builder: popupBuilder),
      ),
      child: child,
    );
  }
}
