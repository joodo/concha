import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:styled_widget/styled_widget.dart';

import '/utils/utils.dart';

import 'extensions.dart';
import 'models.dart';
import 'riverpod.dart';

class _ShortcutsIntent extends InheritedWidget {
  static _ShortcutsIntent of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ShortcutsIntent>()!;
  }

  const _ShortcutsIntent({required super.child, required this.mapping});

  final Map<Shortcut, Intent> mapping;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class ConchaShortcuts extends ConsumerWidget {
  const ConchaShortcuts({
    super.key,
    required this.child,
    required this.intentMapping,
  });

  final Widget child;
  final Map<Shortcut, Intent> intentMapping;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ShortcutsIntent(
      mapping: Map.unmodifiable(intentMapping),
      child: Shortcuts(
        shortcuts: ref
            .watch(shortcutsProvider)
            .where(
              (key, value) => value != null && intentMapping.containsKey(key),
            )
            .map((key, value) => MapEntry(value!, intentMapping[key]!)),
        child: child,
      ),
    );
  }
}

class IgnoreConchaShortcuts extends StatelessWidget {
  const IgnoreConchaShortcuts({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mapping = _ShortcutsIntent.of(context).mapping;

    return Actions(
      actions: mapping.map(
        (key, value) =>
            MapEntry(value.runtimeType, DoNothingAction(consumesKey: false)),
      ),
      child: child,
    );
  }
}

class TooltipWithShortcuts extends ConsumerWidget {
  const TooltipWithShortcuts({
    super.key,
    required this.message,
    required this.shortcuts,
    this.child,
  });

  final String message;
  final List<Shortcut> shortcuts;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyMapping = ref.watch(shortcutsProvider);

    final availibleShortcuts = shortcuts.where(
      (shortcut) => keyMapping.containsKey(shortcut),
    );
    if (availibleShortcuts.isEmpty) {
      return Tooltip(message: message, child: child);
    }

    Widget createLabel(String name) => name
        .asText()
        .textColor(context.colors.onSurface)
        .padding(vertical: 2.0, horizontal: 4.0)
        .decorated(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(4.0),
        );

    final shortcutSpans = availibleShortcuts
        .map<InlineSpan>(
          (shortcut) => WidgetSpan(
            alignment: .middle,
            child: keyMapping[shortcut]!.friendlyNameParts
                .map(createLabel)
                .toList()
                .toRow(mainAxisSize: .min),
          ),
        )
        .intersperse(const TextSpan(text: ' / '));

    return Tooltip(
      richMessage: TextSpan(
        children: [
          TextSpan(text: '$message  '),
          ...shortcutSpans,
        ],
      ),
      child: child,
    );
  }
}

extension TooltipWithShortcutsExtension on Widget {
  Widget tooltipWithShortcuts(String message, {List<Shortcut>? shortcuts}) =>
      TooltipWithShortcuts(
        message: message,
        shortcuts: shortcuts ?? List.empty(),
        child: this,
      );
}
