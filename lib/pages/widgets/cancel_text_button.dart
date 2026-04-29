import 'package:flutter/material.dart';

import '/generated/l10n.dart';
import '/utils/utils.dart';

class CancelTextButton extends StatelessWidget {
  const CancelTextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: Navigator.of(context).maybePop,
      child: S.of(context).cancel.asText(),
    );
  }
}
