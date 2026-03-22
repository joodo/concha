import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class ReadAloudPendingNotifier extends ValueNotifier<bool> {
  ReadAloudPendingNotifier() : super(false);
}

extension ProjectProvidersExtension on Widget {
  Widget projectProviders() => Provider(
    create: (context) => ReadAloudPendingNotifier(),
    dispose: (context, value) => value.dispose(),
    child: this,
  );
}
