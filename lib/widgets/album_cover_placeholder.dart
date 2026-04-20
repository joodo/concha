import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import '/utils/utils.dart';

class AlbumCoverPlaceholder extends StatelessWidget {
  const AlbumCoverPlaceholder({super.key, this.size});
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.music_note_rounded,
      size: size ?? 56.0,
    ).center().backgroundColor(context.colors.surfaceContainerHigh);
  }
}
