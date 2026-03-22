import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';

import '../../services/play_controller.dart';

class TogglePlayFromStartIntent extends Intent {
  const TogglePlayFromStartIntent();
}

class TogglePlayIntent extends Intent {
  const TogglePlayIntent();
}

class DeltaPositionIntent extends Intent {
  const DeltaPositionIntent(this.delta);
  final Duration delta;
}

class DeltaVolumeIntent extends Intent {
  const DeltaVolumeIntent(this.delta);
  final double delta;
}

class DeltaSpeedIntent extends Intent {
  const DeltaSpeedIntent(this.delta);
  final double delta;
}

class DeltaPitchIntent extends Intent {
  const DeltaPitchIntent(this.delta);
  final int delta;
}

class SetVocalVolumeIntent extends Intent {
  final double volume;
  const SetVocalVolumeIntent(this.volume);
}

class MarkStartPoint extends Intent {
  const MarkStartPoint();
}

class ProjectActions extends SingleChildStatefulWidget {
  const ProjectActions({
    required this.playController,
    required Widget super.child,
    super.key,
  });

  final PlayController playController;

  @override
  State<ProjectActions> createState() => _ProjectActionsState();
}

class _ProjectActionsState extends SingleChildState<ProjectActions> {
  final _scopeNode = FocusScopeNode(debugLabel: 'project-actions-scope');
  final _rootFocusNode = FocusNode(debugLabel: 'project-actions-root');

  bool _restoreQueued = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_handleGlobalFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_rootFocusNode.canRequestFocus) _rootFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handleGlobalFocusChange);
    _rootFocusNode.dispose();
    _scopeNode.dispose();
    super.dispose();
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return Actions(
      actions: {
        TogglePlayFromStartIntent: CallbackAction<TogglePlayFromStartIntent>(
          onInvoke: (intent) => _togglePlay(fromStart: true),
        ),
        TogglePlayIntent: CallbackAction<TogglePlayIntent>(
          onInvoke: (intent) => _togglePlay(),
        ),
        DeltaPositionIntent: CallbackAction<DeltaPositionIntent>(
          onInvoke: (intent) {
            final current = widget.playController.positionNotifier.value;
            return widget.playController.seekTo(current + intent.delta);
          },
        ),
        DeltaVolumeIntent: CallbackAction<DeltaVolumeIntent>(
          onInvoke: (intent) {
            final current = widget.playController.volumeNotifier.value;
            widget.playController.setVolume(current + intent.delta);
            return null;
          },
        ),
        DeltaSpeedIntent: CallbackAction<DeltaSpeedIntent>(
          onInvoke: (intent) {
            final current = widget.playController.speedNotifier.value;
            final next = (current + intent.delta).clamp(0.25, 2.0).toDouble();
            widget.playController.setSpeed(next);
            return null;
          },
        ),
        DeltaPitchIntent: CallbackAction<DeltaPitchIntent>(
          onInvoke: (intent) {
            final current = widget.playController.pitchNotifier.value;
            final next = (current + intent.delta).clamp(-7, 7);
            widget.playController.setPitch(next);
            return null;
          },
        ),
        SetVocalVolumeIntent: CallbackAction<SetVocalVolumeIntent>(
          onInvoke: (intent) {
            widget.playController.setSeparateMode(true);
            widget.playController.setVocalVolume(intent.volume);
            return null;
          },
        ),
        MarkStartPoint: CallbackAction<MarkStartPoint>(
          onInvoke: (intent) {
            final position = widget.playController.positionNotifier.value;
            widget.playController.setStartPosition(position);
            return null;
          },
        ),
      },
      child: Shortcuts(
        shortcuts: {
          SingleActivator(LogicalKeyboardKey.space):
              const TogglePlayFromStartIntent(),
          SingleActivator(LogicalKeyboardKey.space, shift: true):
              const TogglePlayIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp): DeltaVolumeIntent(0.1),
          SingleActivator(LogicalKeyboardKey.arrowDown): DeltaVolumeIntent(
            -0.1,
          ),
          SingleActivator(LogicalKeyboardKey.arrowLeft): DeltaPositionIntent(
            Duration(seconds: -10),
          ),
          SingleActivator(LogicalKeyboardKey.arrowRight): DeltaPositionIntent(
            Duration(seconds: 10),
          ),
          SingleActivator(LogicalKeyboardKey.comma): DeltaSpeedIntent(-0.25),
          SingleActivator(LogicalKeyboardKey.period): DeltaSpeedIntent(0.25),
          SingleActivator(LogicalKeyboardKey.bracketLeft): DeltaPitchIntent(-1),
          SingleActivator(LogicalKeyboardKey.bracketRight): DeltaPitchIntent(1),
          SingleActivator(LogicalKeyboardKey.digit1): SetVocalVolumeIntent(1.0),
          SingleActivator(LogicalKeyboardKey.digit2): SetVocalVolumeIntent(0.5),
          SingleActivator(LogicalKeyboardKey.digit3): SetVocalVolumeIntent(0),
          SingleActivator(LogicalKeyboardKey.keyZ): MarkStartPoint(),
        },
        child: FocusScope(
          node: _scopeNode,
          child: Focus(focusNode: _rootFocusNode, child: child!),
        ),
      ),
    );
  }

  void _handleGlobalFocusChange() {
    if (_restoreQueued ||
        _scopeNode.context == null ||
        _rootFocusNode.context == null) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;

    final primaryFocus = FocusManager.instance.primaryFocus;
    final isInScope =
        primaryFocus != null && _isDescendantOf(primaryFocus, _scopeNode);
    if (isInScope) return;

    _restoreQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreQueued = false;
      if (!mounted ||
          _scopeNode.context == null ||
          _rootFocusNode.context == null) {
        return;
      }

      final currentRoute = ModalRoute.of(context);
      if (currentRoute != null && !currentRoute.isCurrent) return;
      if (!_rootFocusNode.canRequestFocus) return;
      _rootFocusNode.requestFocus();
    });
  }

  bool _isDescendantOf(FocusNode node, FocusNode ancestor) {
    FocusNode? current = node;
    while (current != null) {
      if (identical(current, ancestor)) return true;
      current = current.parent;
    }
    return false;
  }

  Future<void> _togglePlay({bool fromStart = false}) {
    if (widget.playController.isPlayNotifier.value) {
      return widget.playController.pause();
    } else {
      return fromStart
          ? widget.playController.playFromStartPoint()
          : widget.playController.play();
    }
  }
}

extension ProjectActionsExtension on Widget {
  Widget projectActions({required PlayController controller}) =>
      ProjectActions(playController: controller, child: this);
}
