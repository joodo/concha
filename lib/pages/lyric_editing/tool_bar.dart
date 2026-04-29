import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:styled_widget/styled_widget.dart';

import '/generated/l10n.dart';
import '/utils/utils.dart';

import 'lyric_field.dart';

class ToolBar extends HookWidget {
  const ToolBar({
    super.key,
    required this.lyricController,
    required this.historyController,
    required this.textFieldFocusNode,
    this.onSeekTo,
  });

  final LyricEditingController lyricController;
  final UndoHistoryController historyController;
  final FocusNode textFieldFocusNode;

  final ValueSetter<Duration>? onSeekTo;

  @override
  Widget build(BuildContext context) {
    final positionbar = ListenableBuilder(
      listenable: lyricController,
      builder: (context, child) {
        final positions = lyricController.selectedPositions;
        final children = [
          if (positions.length == 1)
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: S.of(context).seekToTimepoint,
              onPressed: () {
                onSeekTo?.call(lyricController.selectedPositions.first);
                _refocusTextField();
              },
            ),

          if (positions.length > 1)
            S
                .of(context)
                .selectedTimepoints(positions.length)
                .asText()
                .textColor(context.colors.onSurfaceVariant)
                .padding(left: 24.0),

          if (positions.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                lyricController.offsetSelectedTimestamps(-500.milliseconds);
                onSeekTo?.call(lyricController.selectedPositions.first);
                _refocusTextField();
              },
              label: '- 0.5s'.asText(),
              icon: Icon(Icons.replay_5),
            ),
          if (positions.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                lyricController.offsetSelectedTimestamps(500.milliseconds);
                onSeekTo?.call(lyricController.selectedPositions.first);
                _refocusTextField();
              },
              label: '+ 0.5s'.asText(),
              icon: Icon(Icons.forward_5),
            ),
        ];

        return _buildToolbar(context, children);
      },
    );

    final historyBar = ValueListenableBuilder(
      valueListenable: historyController,
      builder: (context, history, child) {
        return _buildToolbar(context, [
          IconButton(
            onPressed: history.canUndo
                ? () {
                    historyController.undo();
                    _refocusTextField();
                  }
                : null,
            icon: Icon(Icons.undo),
          ),
          IconButton(
            onPressed: history.canRedo
                ? () {
                    historyController.redo();
                    _refocusTextField();
                  }
                : null,
            icon: Icon(Icons.redo),
          ),
        ]);
      },
    );

    return [historyBar, const Spacer(), positionbar].toRow();
  }

  Widget _buildToolbar(BuildContext context, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 6,
      shape: const StadiumBorder(),
      color: context.colors.surfaceContainerHigh,
      child: AnimatedSize(
        duration: 150.milliseconds,
        curve: Curves.easeOutCubic,
        child: children.toRow(mainAxisSize: .min).padding(all: 8.0),
      ),
    ).constrained(height: 54.0);
  }

  void _refocusTextField() {
    runAfterBuild(() {
      if (!textFieldFocusNode.hasFocus) textFieldFocusNode.requestFocus();
    });
  }
}
