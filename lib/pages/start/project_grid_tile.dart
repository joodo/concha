import 'dart:io';

import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import '/models/models.dart';
import '/utils/utils.dart';

class ProjectGridTile extends StatelessWidget {
  const ProjectGridTile({
    required this.project,
    this.onSelect,
    super.key,
    this.onDelete,
  });

  final Project project;
  final VoidCallback? onSelect;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final data = project.metadata;
    final coverFile = File(project.path.cover);

    final tile = GridTile(
      footer: GridTileBar(
        backgroundColor: Colors.black54,
        title: Text(data.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: data.artist?.asText(),
      ),
      child: FutureBuilder(
        future: coverFile.exists(),
        initialData: false,
        builder: (context, snapshot) => snapshot.data == true
            ? Ink.image(image: FileImage(coverFile), fit: .cover)
            : Icon(Icons.music_note_rounded, size: 56.0).center(),
      ),
    );

    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onSelect,
        onSecondaryTapDown: (details) {
          final o = details.globalPosition;
          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(o.dx, o.dy, o.dx, o.dy),
            items: [PopupMenuItem(onTap: onDelete, child: '删除'.asText())],
          );
        },
        child: tile,
      ),
    );
  }
}
