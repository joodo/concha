import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:styled_widget/styled_widget.dart';

import '/projects/riverpod.dart';
import '/utils/utils.dart';

class ProjectGridTile extends ConsumerWidget {
  const ProjectGridTile({
    required this.projectId,
    this.onSelect,
    super.key,
    this.onDelete,
  });

  final String projectId;
  final VoidCallback? onDelete, onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectDetailProvider(projectId)).value;
    if (project == null) return const SizedBox.shrink();

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
        onSecondaryTapDown: (details) => context.showPopupMenu(
          details.globalPosition,
          [PopupMenuItem(onTap: onDelete, child: '删除'.asText())],
        ),
        child: tile,
      ),
    );
  }
}
