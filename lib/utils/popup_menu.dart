import 'package:flutter/material.dart';

extension PopupMeneExtension on BuildContext {
  Future<T?> showPopupMenu<T>(Offset position, List<PopupMenuEntry<T>> items) =>
      showMenu(
        context: this,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx,
          position.dy,
        ),
        items: items,
      );
}
