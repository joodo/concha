import 'package:flutter/foundation.dart';

class PendingDeleteAction<T> {
  final T value;
  final VoidCallback onUndo;
  final AsyncCallback onCommit;

  PendingDeleteAction({
    required this.value,
    required this.onUndo,
    required this.onCommit,
  });

  void undo() => onUndo();

  Future<void> commit() => onCommit();
}
