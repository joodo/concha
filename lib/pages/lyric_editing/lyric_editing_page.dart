import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:styled_widget/styled_widget.dart';

import '/generated/l10n.dart';
import '/lyric/lyric.dart';
import '/pages/lyric_editing/lyric_field.dart';
import '/pages/lyric_editing/playback_bar.dart';
import '/pages/lyric_editing/tool_bar.dart';
import '/play_controller/play_controller.dart';
import '/utils/utils.dart';

import '../widgets/animated_linear_indicator.dart';
import '../widgets/confirm_pop_without_result.dart';

class LyricEditingPage extends HookConsumerWidget {
  const LyricEditingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyricEditingController = useValue(
      LyricEditingController(text: context.routeArguments['lrc']),
      onDispose: (value) => value.dispose(),
    );
    useEffect(() {
      lyricEditingController.selection = const TextSelection.collapsed(
        offset: 0,
      );
      return null;
    }, []);

    final highlightController = useValue(
      LineHighlightController(),
      onDispose: (controller) => controller.dispose(),
    );
    useEffect(() {
      void syncLrcModel() => highlightController.lrcModel =
          lyricEditingController.lrcModelNotifier.value;

      lyricEditingController.lrcModelNotifier.addListener(syncLrcModel);
      syncLrcModel();

      return null;
    }, []);

    final playController = ref.playController!;
    useEffect(() {
      void updateHighlight() {
        highlightController.updateProgress(
          playController.positionNotifier.value,
        );
      }

      playController.positionNotifier.addListener(updateHighlight);
      updateHighlight();

      return () =>
          playController.positionNotifier.removeListener(updateHighlight);
    }, []);

    final undoController = useValue(
      UndoHistoryController(),
      onDispose: (value) => value.dispose(),
    );

    final modified = useState(false);
    undoController.addListener(
      () => modified.value = undoController.value.canUndo,
    );

    final isProofreading = useState(false);
    useEffect(() {
      lyricEditingController.enabled = !isProofreading.value;
      return null;
    }, [isProofreading.value]);

    final appBar = AppBar(
      title: [
        context.routeArguments['title'],
        if (modified.value) S.of(context).modified,
      ].join(' ').asText(),
      actions: [
        TextButton.icon(
          onPressed: isProofreading.value
              ? null
              : () async {
                  final original = await _getOriginalLyric(context);
                  if (original == null) return;

                  try {
                    isProofreading.value = true;

                    final proofreaded = await lyricProofread(
                      lyricEditingController.text,
                      original,
                    );

                    lyricEditingController.value = TextEditingValue(
                      text: proofreaded,
                      selection: const TextSelection.collapsed(offset: 0),
                    );
                  } catch (e) {
                    if (context.mounted) {
                      context.showSnackBarText(e.toString());
                    }
                  } finally {
                    isProofreading.value = false;
                  }
                },
          label: Text(
            isProofreading.value
                ? S.of(context).proofreading
                : S.of(context).proofread,
          ),
          icon: Icon(Icons.spellcheck),
        ),
        8.0.asWidth(),
        TextButton.icon(
          onPressed: modified.value
              ? () =>
                    Navigator.of(context).maybePop(lyricEditingController.text)
              : null,
          label: S.of(context).save.asText(),
          icon: const Icon(Icons.check),
        ),
        8.0.asWidth(),
      ],
    );

    final body = [
      AnimatedLinearIndicator(isRunning: isProofreading.value),
      SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 96.0),
        child: LyricField(
          enabled: !isProofreading.value,
          controller: lyricEditingController,
          highlightController: highlightController,
          historyController: undoController,
        ),
      ).expanded(),
    ].toColumn();

    final bottomBar = PlaybackBar(controller: playController);

    final scaffold = Scaffold(
      appBar: appBar,
      body: [
        body,
        ToolBar(
          lyricController: lyricEditingController,
          historyController: undoController,
          onSeekTo: (position) => playController.seekTo(position),
        ).positioned(bottom: 16.0, left: 16.0, right: 16.0),
      ].toStack(),
      bottomNavigationBar: bottomBar,
    );

    return ConfirmPopWithoutResult(when: () => modified.value, child: scaffold);
  }

  Future<String?> _getOriginalLyric(BuildContext context) async {
    final dialog = HookBuilder(
      builder: (context) {
        final controller = useTextEditingController();
        void submit() {
          if (controller.text.isEmpty) return;
          Navigator.of(context).pop(controller.text);
        }

        return AlertDialog(
          icon: const Icon(Icons.spellcheck),
          content:
              [
                    S.of(context).proofreadHint.asText(),
                    TextField(
                      controller: controller,
                      onSubmitted: (_) => submit(),
                      maxLines: 10,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: S.of(context).pasteLyricsHere,
                      ),
                    ),
                  ]
                  .toColumn(
                    crossAxisAlignment: .start,
                    mainAxisSize: .min,
                    separator: 16.0.asHeight(),
                  )
                  .constrained(width: 400.0),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: S.of(context).cancel.asText(),
            ),
            ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, value, child) {
                return TextButton(
                  onPressed: value.text.isNotEmpty ? submit : null,
                  child: S.of(context).proofread.asText(),
                );
              },
            ),
          ],
        );
      },
    );

    return showModal<String>(context: context, builder: (context) => dialog);
  }
}
