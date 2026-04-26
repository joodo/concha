import 'package:animations/animations.dart';
import '/generated/l10n.dart';
import '/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

class ConfirmPopWithoutResult extends StatelessWidget {
  const ConfirmPopWithoutResult({super.key, this.when, required this.child});
  final ValueGetter<bool>? when;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final willConfirm = when?.call() ?? true;
        if (!willConfirm || result != null) {
          return Navigator.of(context).pop(result);
        }

        final dialog = AlertDialog(
          title: S.of(context).discardChanges.asText(),
          content: S
              .of(context)
              .metadataWillBeRestoredToTheStateBeforeModification
              .asText()
              .constrained(maxWidth: 400.0),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: S.of(context).cancel.asText(),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: S.of(context).discard.asText(),
            ),
          ],
        );

        final discard = await showModal<bool>(
          context: context,
          builder: (context) => dialog,
        );

        if (context.mounted && discard == true) Navigator.of(context).pop();
      },
      child: child,
    );
  }
}
