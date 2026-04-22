import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

extension CustomHooksExtension on HookWidget {
  T useValue<T>(T value) => useMemoized(() => value);
  GlobalKey useGlobalKey() => useValue(GlobalKey());
}
