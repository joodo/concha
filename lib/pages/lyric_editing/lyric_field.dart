import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:styled_widget/styled_widget.dart';

import '/utils/utils.dart';

import 'utils.dart';

class LyricField extends HookWidget {
  const LyricField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.historyController,
    required this.highlightController,
    required this.textFieldFocusNode,
  });

  final LyricEditingController controller;
  final LineHighlightController highlightController;
  final UndoHistoryController historyController;
  final FocusNode textFieldFocusNode;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textStyle = context.textStyles.bodyLarge!.copyWith(
      fontFamily: _monospaceFontName,
      height: 2.0,
    );
    final contentPadding = EdgeInsets.only(left: 24.0);

    return [
      RepaintBoundary(
        child: CustomPaint(
          painter: LineHighlightPainter(
            controller: highlightController,
            style: textStyle,
            highlightColor: context.colors.tertiaryContainer,
            contentPadding: contentPadding,
          ),
        ),
      ).positioned(top: 0, bottom: 0, left: 0, right: 0),
      TextField(
        enabled: enabled,
        controller: controller,
        undoController: historyController,
        focusNode: textFieldFocusNode,
        maxLines: null,
        autofocus: true,
        style: textStyle.copyWith(
          color: context.colors.onSurface.withAlpha(
            enabled ? 255 : 0.38.toUint8,
          ),
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: contentPadding,
        ),
      ),
    ].toStack();
  }

  String get _monospaceFontName => switch (true) {
    _ when Platform.isWindows => 'Consolas',
    _ when Platform.isMacOS => 'Menlo',
    _ when Platform.isLinux => 'Ubuntu Mono',
    _ when Platform.isIOS => 'Courier',
    _ when Platform.isAndroid => 'monospace',
    _ => 'monospace',
  };
}

class LineHighlightPainter extends CustomPainter {
  LineHighlightPainter({
    required this.controller,
    required this.style,
    required this.highlightColor,
    this.contentPadding = EdgeInsets.zero,
  }) : super(repaint: controller);

  final LineHighlightController controller;
  final TextStyle style;
  final Color highlightColor;
  final EdgeInsets contentPadding;

  @override
  void paint(Canvas canvas, Size size) {
    final text = controller.lrcModel.text;
    final lineIndex = controller.value;
    if (lineIndex == null || text.isEmpty) return;

    final contentWidth =
        size.width - contentPadding.left - contentPadding.right;

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    textPainter.layout(maxWidth: contentWidth);
    // textPainter.paint(canvas, Offset.zero);

    final lines = text.split('\n');
    final start = lines.sublist(0, lineIndex).join('\n').length;
    final end = start + lines[lineIndex].length + 1;

    final boxes = textPainter
        .getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: end),
        )
        .where((box) => box.right - box.left > 0);
    if (boxes.isEmpty) return;

    /*
    final paint2 = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    for (final box in boxes) {
      canvas.drawRect(box.toRect(), paint2);
    }
    */

    double top = boxes.first.top;
    double bottom = boxes.first.bottom;
    for (final box in boxes) {
      if (box.top < top) top = box.top;
      if (box.bottom > bottom) bottom = box.bottom;
    }
    final mergedRect = Rect.fromLTWH(
      0,
      top + contentPadding.top,
      size.width,
      bottom - top + contentPadding.top,
    );

    final padding = EdgeInsets.symmetric(vertical: 8.0);
    final inflatedRect = padding.inflateRect(mergedRect);

    final roundedRect = RRect.fromRectAndRadius(
      inflatedRect,
      const Radius.circular(8.0),
    );

    final paint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(roundedRect, paint);
  }

  @override
  bool shouldRepaint(covariant LineHighlightPainter oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.highlightColor != highlightColor;
  }
}

class LyricEditingController extends TextEditingController {
  LyricEditingController({super.text}) {
    _updateModel(text);
  }

  @override
  void dispose() {
    _lrcModelNotifier.dispose();
    super.dispose();
  }

  final _lrcModelNotifier = ValueNotifier<LrcModel>(LrcModel.empty());
  ValueListenable<LrcModel> get lrcModelNotifier => _lrcModelNotifier;

  void _updateModel(String newText) {
    final map = <int, List<TimestampRange>>{};

    newText.split('\n').forEachIndexed((index, line) {
      final matches = LrcRegExps.timestamp.allMatches(line);
      if (matches.isEmpty) return;

      final ranges = <TimestampRange>[];
      for (final match in matches) {
        final minutes = match.group(1);
        final seconds = match.group(2);
        String milliseconds = match.group(3) ?? '0';
        if (milliseconds.length > 3) {
          milliseconds = milliseconds.substring(0, 3);
        }

        Duration duration = Duration(
          minutes: int.parse(minutes!),
          seconds: int.parse(seconds!),
          milliseconds: int.parse(milliseconds.padRight(3, '0')),
        );

        final range = TimestampRange(match.start, match.end, duration);
        ranges.add(range);
      }

      map[index] = List.unmodifiable(ranges);
    });

    _lrcModelNotifier.value = LrcModel(
      text: newText,
      lineTimestampRangeMapping: Map.unmodifiable(map),
    );
  }

  bool _enabled = true;
  set enabled(bool newValue) {
    if (_enabled == newValue) return;
    _enabled = newValue;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!_enabled) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    if (_selectedRanges.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final selectedLineIndex = _selectedRanges.length == 1
        ? _selectedRanges.keys.first
        : null;

    final List<TextSpan> children = [];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final lineStyle = i == selectedLineIndex
          ? style?.copyWith(color: context.colors.primary)
          : style;

      String lineText = lines[i];
      // Add newline character back for all lines except the last one
      if (i < lines.length - 1) lineText += '\n';

      final ranges = _selectedRanges[i];
      if (ranges == null || ranges.isEmpty) {
        children.add(TextSpan(text: lineText, style: lineStyle));
        continue;
      }

      int startPos = 0;
      for (final range in ranges) {
        children.addAll([
          TextSpan(
            text: lineText.substring(startPos, range.start),
            style: lineStyle,
          ),
          TextSpan(
            text: lineText.substring(range.start, range.end),
            style: lineStyle?.copyWith(
              backgroundColor: context.colors.errorContainer.withAlpha(150),
            ),
          ),
        ]);
        startPos = range.end;
      }
      children.add(
        TextSpan(text: lineText.substring(ranges.last.end), style: lineStyle),
      );
    }

    return TextSpan(style: style, children: children);
  }

  final _selectedRanges = <int, List<TimestampRange>>{};
  Iterable<Duration> get selectedPositions => _selectedRanges.values.expand(
    (ranges) => ranges.map((range) => range.position),
  );
  void _updateSelectedRanges(TextEditingValue newValue) {
    _selectedRanges.clear();

    final TextEditingValue(:selection, :text) = newValue;

    if (!selection.isValid) return;

    int lineCount = 0;
    int lineStart = 0;
    int charIndex = 0;

    for (; charIndex < selection.start; charIndex++) {
      if (text.codeUnitAt(charIndex) == 10) {
        lineStart = charIndex + 1;
        lineCount++;
      }
    }
    final startLineIndex = lineCount;
    final startLinePos = charIndex - lineStart;

    for (; charIndex < selection.end; charIndex++) {
      if (text.codeUnitAt(charIndex) == 10) {
        lineStart = charIndex + 1;
        lineCount++;
      }
    }
    final endLineIndex = lineCount;
    final endLinePos = charIndex - lineStart;

    final lineMapping = _lrcModelNotifier.value.lineTimestampRangeMapping;

    for (
      int lineIndex = startLineIndex;
      lineIndex <= endLineIndex;
      lineIndex++
    ) {
      final ranges = lineMapping[lineIndex];
      if (ranges == null || ranges.isEmpty) continue;

      int start = 0;
      if (lineIndex == startLineIndex) {
        start = ranges.length;
        final s = ranges.indexWhere((r) => r.end > startLinePos);
        if (s >= 0) start = s;
      }
      int? end;
      if (lineIndex == endLineIndex) {
        end = start;
        final e = ranges.lastIndexWhere((r) => r.start < endLinePos);
        if (e >= 0) end = e + 1;
      }

      _selectedRanges[lineIndex] = ranges.sublist(start, end);
    }
  }

  void offsetSelectedTimestamps(Duration offset) {
    if (_selectedRanges.isEmpty) return;

    final newText = text
        .split('\n')
        .mapIndexed((lineIndex, line) {
          if (!_selectedRanges.containsKey(lineIndex)) return line;

          final ranges = _selectedRanges[lineIndex]!;
          for (final range in ranges.reversed) {
            final newTimestamp = _getLrcTimestamp(range.position + offset);
            line = line.replaceRange(range.start, range.end, newTimestamp);
          }

          return line;
        })
        .join('\n');

    value = value.copyWith(text: newText);
  }

  String _getLrcTimestamp(Duration duration) {
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    int milliseconds = (duration.inMilliseconds % 1000) ~/ 10;
    String ms = milliseconds.toString().padLeft(2, '0');

    return "[$minutes:$seconds.$ms]";
  }

  @override
  set value(TextEditingValue newValue) {
    if (newValue.text != value.text) _updateModel(newValue.text);
    if (newValue != value) _updateSelectedRanges(newValue);
    super.value = newValue;
  }
}

class LineHighlightController extends ChangeNotifier
    implements ValueListenable<int?> {
  LineHighlightController();

  int? _value;
  @override
  int? get value => _value;
  void _setValue(int? newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  Duration _position = Duration.zero;
  void updateProgress(Duration position) {
    _position = position;
    _updateHighlightLineIndex();
  }

  void _updateHighlightLineIndex() {
    final i = lowerBound(
      _timestampLineMapping.keys.toList(),
      _position,
      compare: (a, b) => a <= b ? -1 : 1,
    );
    if (i == 0) {
      _setValue(null);
    } else {
      _setValue(_timestampLineMapping.values.elementAt(i - 1));
    }
  }

  LrcModel _lrcModel = LrcModel.empty();
  LrcModel get lrcModel => _lrcModel;

  final _timestampLineMapping = SplayTreeMap<Duration, int>();
  set lrcModel(LrcModel newValue) {
    if (newValue == _lrcModel) return;
    _lrcModel = newValue;

    _timestampLineMapping.clear();
    _lrcModel.lineTimestampRangeMapping.forEach((lineIndex, ranges) {
      for (final range in ranges) {
        _timestampLineMapping[range.position] = lineIndex;
      }
    });
    _updateHighlightLineIndex();
  }
}

@immutable
class LrcModel {
  const LrcModel({required this.text, required this.lineTimestampRangeMapping});

  const LrcModel.empty() : text = '', lineTimestampRangeMapping = const {};

  final String text;
  final Map<int, List<TimestampRange>> lineTimestampRangeMapping;
}

@immutable
class TimestampRange {
  const TimestampRange(this.start, this.end, this.position);
  final int start;
  final int end;
  final Duration position;

  bool contains(int value) => value >= start && value <= end;

  @override
  String toString() => 'IntRange($start, $end)';
}
