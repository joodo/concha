import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';

import 'providers.dart';
import '../../services/gemini_tts_service.dart';
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

class SetMixIntent extends Intent {
  const SetMixIntent({required this.vocalVolume, required this.instruVolume});
  final double vocalVolume;
  final double instruVolume;
}

class MarkStartPoint extends Intent {
  const MarkStartPoint();
}

class ReadAloudCurrentLyricIntent extends Intent {
  const ReadAloudCurrentLyricIntent();
}

class ProjectActions extends SingleChildStatefulWidget {
  const ProjectActions({super.key, required Widget super.child});

  @override
  State<ProjectActions> createState() => _ProjectActionsState();
}

class _ProjectActionsState extends SingleChildState<ProjectActions> {
  late final _playController = context.read<PlayController>();
  late final _lyricController = context.read<LyricController>();

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
            final current = _playController.positionNotifier.value;
            return _playController.seekTo(current + intent.delta);
          },
        ),
        DeltaVolumeIntent: CallbackAction<DeltaVolumeIntent>(
          onInvoke: (intent) {
            final current = _playController.volumeNotifier.value;
            _playController.setVolume(current + intent.delta);
            return null;
          },
        ),
        DeltaSpeedIntent: CallbackAction<DeltaSpeedIntent>(
          onInvoke: (intent) {
            final current = _playController.speedNotifier.value;
            final next = (current + intent.delta).clamp(0.25, 2.0).toDouble();
            _playController.setSpeed(next);
            return null;
          },
        ),
        DeltaPitchIntent: CallbackAction<DeltaPitchIntent>(
          onInvoke: (intent) {
            final current = _playController.pitchNotifier.value;
            final next = (current + intent.delta).clamp(-7, 7);
            _playController.setPitch(next);
            return null;
          },
        ),
        SetMixIntent: CallbackAction<SetMixIntent>(
          onInvoke: (intent) {
            _playController.setSeparateMode(true);
            _playController.setVocalVolume(intent.vocalVolume);
            _playController.setInstruVolume(intent.instruVolume);
            return null;
          },
        ),
        MarkStartPoint: CallbackAction<MarkStartPoint>(
          onInvoke: (intent) {
            final position = _playController.positionNotifier.value;
            _playController.setStartPosition(position);
            return null;
          },
        ),
        ReadAloudCurrentLyricIntent:
            CallbackAction<ReadAloudCurrentLyricIntent>(
              onInvoke: (intent) async {
                final busyNotifier = context.read<ReadAloudPendingNotifier>();
                busyNotifier.value = true;

                try {
                  final model = _lyricController.lyricNotifier.value;
                  if (model == null || model.lines.isEmpty) return;
                  final i = _lyricController.activeIndexNotifiter.value;
                  if (i < 0 || i >= model.lines.length) return;

                  await _playController.pause();
                  final currentLyric = model.lines[i].text;
                  final voiceBytes = await GeminiTtsService().getVoice(
                    currentLyric,
                  );
                  await _playController.insertInterlude(voiceBytes);
                  return null;
                } finally {
                  busyNotifier.value = false;
                }
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
          SingleActivator(LogicalKeyboardKey.digit1): SetMixIntent(
            vocalVolume: 1.0,
            instruVolume: 1.0,
          ),
          SingleActivator(LogicalKeyboardKey.digit2): SetMixIntent(
            vocalVolume: 0.4,
            instruVolume: 1.0,
          ),
          SingleActivator(LogicalKeyboardKey.digit3): SetMixIntent(
            vocalVolume: 0,
            instruVolume: 1.0,
          ),
          SingleActivator(LogicalKeyboardKey.digit4): SetMixIntent(
            vocalVolume: 1.0,
            instruVolume: 0.1,
          ),
          SingleActivator(LogicalKeyboardKey.keyZ): MarkStartPoint(),
          SingleActivator(LogicalKeyboardKey.keyS):
              ReadAloudCurrentLyricIntent(),
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
    if (_playController.isPlayNotifier.value) {
      return _playController.pause();
    } else {
      return fromStart
          ? _playController.playFromStartPoint()
          : _playController.play();
    }
  }
}

extension ProjectActionsExtension on Widget {
  Widget projectActions() => ProjectActions(child: this);
}
