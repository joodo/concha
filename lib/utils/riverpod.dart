import 'dart:async';

import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

mixin LoadPersistOrFetch<T> on AnyNotifier<AsyncValue<T>, T> {
  Future<T> loadPersistOrFetch({
    required PersistResult persist,
    required Future<T> Function() fetch,
  }) async {
    if (!ref.isFirstBuild) return await fetch();

    final link = ref.keepAlive();
    await persist.future;
    if (state.hasValue) {
      link.close();
      return state.requireValue;
    }

    try {
      return await fetch();
    } finally {
      link.close();
    }
  }
}

extension CacheForExtension on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, link.close);
    onDispose(timer.cancel);
  }
}
