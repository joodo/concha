import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/shortcuts/riverpod.dart';

import 'models.dart';

extension SingleActivatorFriendlyNameExtension on SingleActivator {
  List<String> get friendlyNameParts {
    List<String> parts = [];

    final bool isApple = !kIsWeb && (Platform.isMacOS || Platform.isIOS);
    if (isApple) {
      if (control) parts.add('⌃');
      if (alt) parts.add('⌥');
      if (shift) parts.add('⇧');
      if (meta) parts.add('⌘');
    } else {
      if (control) parts.add('Ctrl');
      if (alt) parts.add('Alt');
      if (shift) parts.add('Shift');
      if (meta) parts.add('Win');
    }

    parts.add(_getReadableTrigger(trigger));
    return parts;
  }

  String _getReadableTrigger(LogicalKeyboardKey key) {
    return switch (key) {
      .arrowUp => '↑',
      .arrowDown => '↓',
      .arrowLeft => '←',
      .arrowRight => '→',

      .enter => '↵',
      .tab => '⇥',
      .space => 'Space',
      .backspace => 'Backspace',
      .delete => 'Del',
      .escape => 'Esc',

      _ => key.keyLabel,
    };
  }
}

extension TooltipWithShortcutsExtension on WidgetRef {
  String tooltipWithShortcuts(String tooltip, List<Shortcut> shortcuts) {
    final activators = shortcuts
        .map((e) => watch(shortcutsProvider)[e])
        .where((e) => e != null)
        .cast<SingleActivator>();
    if (activators.isEmpty) return tooltip;

    final shortcutsHint = activators
        .map((e) => e.friendlyNameParts.join('+'))
        .join(' / ');
    return '$tooltip ( $shortcutsHint )';
  }
}
