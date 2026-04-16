import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/generated/l10n.dart';
import '/lyric_controller/lyric_controller.dart';
import '/play_controller/play_controller.dart';
import '/preferences/preferences.dart';
import '/shortcuts/shortcuts.dart';
import '/tts/tts.dart';
import '/utils/utils.dart';

import 'riverpod.dart';

class TogglePlayIntent extends Intent {
  const TogglePlayIntent();
}

class DeltaPositionIntent extends Intent {
  const DeltaPositionIntent(this.delta);
  final int delta;
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

class ReadAloudIntent extends Intent {
  final String? text;
  const ReadAloudIntent(String this.text);
  const ReadAloudIntent.currentLyric() : text = null;
}

class ProjectActions extends HookConsumerWidget {
  const ProjectActions({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scopeNode = useFocusScopeNode();
    final rootFocusNode = useFocusNode();
    useEffect(() {
      runAfterBuild(() {
        if (!context.mounted) return;
        if (rootFocusNode.canRequestFocus) rootFocusNode.requestFocus();
      });
      return null;
    }, []);

    final restoreQueued = useRef(false);
    useEffect(() {
      void handleGlobalFocusChange() {
        if (restoreQueued.value ||
            scopeNode.context == null ||
            rootFocusNode.context == null) {
          return;
        }

        final route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) return;

        final primaryFocus = FocusManager.instance.primaryFocus;
        final isInScope =
            primaryFocus != null && _isDescendantOf(primaryFocus, scopeNode);
        if (isInScope) return;

        restoreQueued.value = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          restoreQueued.value = false;
          if (!context.mounted ||
              scopeNode.context == null ||
              rootFocusNode.context == null) {
            return;
          }

          final currentRoute = ModalRoute.of(context);
          if (currentRoute != null && !currentRoute.isCurrent) return;
          if (!rootFocusNode.canRequestFocus) return;
          rootFocusNode.requestFocus();
        });
      }

      FocusManager.instance.addListener(handleGlobalFocusChange);
      return () =>
          FocusManager.instance.removeListener(handleGlobalFocusChange);
    }, []);

    final play = useCallback(() {
      final fromStart = ref.read(preferenceProvider<bool>(.playLoop))!;
      return fromStart
          ? ref.playController!.playFromStartPoint()
          : ref.playController!.play();
    });

    final getCurrentLyricStart = useCallback(({int offset = 0}) {
      final lyricController = ref.lyricController!;

      final lyricModel = lyricController.lyricNotifier.value;
      if (lyricModel == null || lyricModel.lines.isEmpty) return null;

      final index = lyricController.activeIndexNotifiter.value + offset;
      final targetIndex = index.clamp(0, lyricModel.lines.length - 1);
      final start = lyricModel.lines[targetIndex].start;

      return start - lyricController.lyricOffset.milliseconds;
    });

    final pauseToLyricStart = useCallback(() async {
      final playController = ref.playController!;

      final position = getCurrentLyricStart();
      if (position == null) {
        return playController.pause();
      }

      await playController.pause();
      await playController.seekTo(position);
    });

    return Actions(
      actions: {
        TogglePlayIntent: CallbackAction<TogglePlayIntent>(
          onInvoke: (intent) {
            final playController = ref.playController!;
            if (!playController.isPlayNotifier.value) return play();

            final attach = ref.read(preferenceProvider<bool>(.attachToLyric))!;
            return attach ? pauseToLyricStart() : playController.pause();
          },
        ),
        DeltaPositionIntent: CallbackAction<DeltaPositionIntent>(
          onInvoke: (intent) {
            final playController = ref.playController!;

            final attach = ref.read(preferenceProvider<bool>(.attachToLyric))!;
            final lyricStart = getCurrentLyricStart(offset: intent.delta);

            if (!attach || lyricStart == null) {
              final current = playController.positionNotifier.value;
              final deltaDuration = 5.seconds * intent.delta;
              return playController.seekTo(current + deltaDuration);
            } else {
              return playController.seekTo(lyricStart);
            }
          },
        ),
        DeltaVolumeIntent: CallbackAction<DeltaVolumeIntent>(
          onInvoke: (intent) {
            final playController = ref.playController!;

            final current = playController.volumeNotifier.value;
            playController.setVolume(current + intent.delta);
            return null;
          },
        ),
        DeltaSpeedIntent: CallbackAction<DeltaSpeedIntent>(
          onInvoke: (intent) {
            final playController = ref.playController!;

            final current = playController.speedNotifier.value;
            final next = (current + intent.delta).clamp(0.25, 2.0).toDouble();
            playController.setSpeed(next);
            return null;
          },
        ),
        DeltaPitchIntent: CallbackAction<DeltaPitchIntent>(
          onInvoke: (intent) {
            final playController = ref.playController!;

            final current = playController.pitchNotifier.value;
            final next = (current + intent.delta).clamp(-7, 7);
            playController.setPitch(next);
            return null;
          },
        ),
        SetMixIntent: CallbackAction<SetMixIntent>(
          onInvoke: (intent) {
            final playController = ref.playController!;

            playController.setSeparateMode(true);
            playController.setVocalVolume(intent.vocalVolume);
            playController.setInstruVolume(intent.instruVolume);
            return null;
          },
        ),
        MarkStartPoint: CallbackAction<MarkStartPoint>(
          onInvoke: (intent) {
            final playController = ref.playController!;

            final position = playController.positionNotifier.value;
            playController.setStartPosition(position);
            return null;
          },
        ),
        ReadAloudIntent: CallbackAction<ReadAloudIntent>(
          onInvoke: (intent) async {
            final playController = ref.playController!;

            try {
              String? text = intent.text;
              if (text == null) {
                final lyricController = ref.lyricController!;
                final currentLyric = lyricController.currentText;
                if (currentLyric == null) return;

                text = currentLyric;
              }

              text = text.trim();
              if (text.isEmpty) return;

              final voiceBytes = await readAloud.run(
                ref,
                (transaction) =>
                    transaction.get(textVoiceProvider(text!).future),
              );
              await playController.insertInterlude(voiceBytes);
              return null;
            } catch (e) {
              if (context.mounted) {
                context.showSnackBarText(
                  S.of(context).failedToReadAloudPleaseRetry,
                );
              }
              rethrow;
            } finally {
              readAloud.reset(ref);
            }
          },
        ),
      },
      child: Shortcuts(
        shortcuts: ref.watch(shortcutsIntentMapProvider),
        child: FocusScope(
          node: scopeNode,
          child: Focus(focusNode: rootFocusNode, child: child),
        ),
      ),
    );
  }

  bool _isDescendantOf(FocusNode node, FocusNode ancestor) {
    FocusNode? current = node;
    while (current != null) {
      if (identical(current, ancestor)) return true;
      current = current.parent;
    }
    return false;
  }
}
