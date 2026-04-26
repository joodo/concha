import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:styled_widget/styled_widget.dart';

import '/generated/l10n.dart';
import '/lyric/lyric.dart';
import '/utils/utils.dart';

import '../widgets/animated_linear_indicator.dart';
import '../widgets/confirm_pop_without_result.dart';

class LyricEditingDialog extends HookWidget {
  const LyricEditingDialog({
    super.key,
    required this.initValue,
    required this.title,
  });
  final String initValue;
  final String title;

  @override
  Widget build(BuildContext context) {
    final textController = useValue(
      _LyricEditingController(text: initValue),
      onDispose: (value) => value.dispose(),
    );
    useEffect(() {
      textController.selection = const TextSelection.collapsed(offset: 0);
      return null;
    }, []);

    final undoController = useValue(UndoHistoryController());
    useEffect(() => undoController.dispose, [undoController]);
    final historyValue = useValueListenable(undoController);

    final modified = useState(false);
    undoController.addListener(
      () => modified.value = undoController.value.canUndo,
    );

    final isProofreading = useState(false);

    final appBar = AppBar(
      leading: const CloseButton(),
      title: [
        title,
        if (modified.value) S.of(context).modified,
      ].join(' ').asText(),
      actions: [
        IconButton(
          onPressed: historyValue.canUndo ? undoController.undo : null,
          icon: Icon(Icons.undo),
        ),
        IconButton(
          onPressed: historyValue.canRedo ? undoController.redo : null,
          icon: Icon(Icons.redo),
        ),
        8.0.asWidth(),
        TextButton.icon(
          onPressed: isProofreading.value
              ? null
              : () async {
                  final original = await _getOriginalLyric(context);
                  if (original == null) return;

                  try {
                    isProofreading.value = true;

                    final proofreaded = await lyricProofread(
                      textController.text,
                      original,
                    );

                    textController.value = TextEditingValue(
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
              ? () => Navigator.of(context).maybePop(textController.text)
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
        padding: EdgeInsets.all(16.0),
        child: TextField(
          enabled: !isProofreading.value,
          controller: textController,
          undoController: undoController,
          maxLines: null,
          autofocus: true,
          style: context.textStyles.bodyLarge!.copyWith(height: 2.0),
          decoration: InputDecoration(border: InputBorder.none),
        ),
      ).expanded(),
    ].toColumn();

    final scaffold = Scaffold(appBar: appBar, body: body);

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

class _LyricEditingController extends TextEditingController {
  _LyricEditingController({super.text}) {
    addListener(() {
      int? newLine;

      final cursorPosition = selection.baseOffset;
      if (cursorPosition >= 0) {
        final textBeforeCursor = text.substring(0, cursorPosition);
        newLine = textBeforeCursor.split('\n').length - 1;
      }

      if (_selectedLine != newLine) {
        _selectedLine = newLine;
        notifyListeners();
      }
    });
  }

  int? _selectedLine;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> children = [];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String lineText = lines[i];
      // Add newline character back for all lines except the last one
      if (i < lines.length - 1) lineText += '\n';

      if (i == _selectedLine) {
        children.add(
          TextSpan(
            text: lineText,
            style: style?.copyWith(color: context.colors.primary),
          ),
        );
      } else {
        children.add(TextSpan(text: lineText, style: style));
      }
    }

    return TextSpan(style: style, children: children);
  }
}
