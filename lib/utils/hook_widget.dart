import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

T useValue<T>(T value, {ValueSetter<T>? onDispose}) {
  if (onDispose != null) {
    useEffect(
      () =>
          () => onDispose(value),
      const [],
    );
  }
  return useMemoized(() => value);
}

GlobalKey<T> useGlobalKey<T extends State<StatefulWidget>>() =>
    useValue<GlobalKey<T>>(GlobalKey());

void useInitiate(VoidCallback init) => useEffect(() {
  init();
  return null;
}, []);
