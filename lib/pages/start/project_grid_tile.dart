import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../utils/utils.dart';

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

    final tile = GridTile(
      footer: GridTileBar(
        backgroundColor: Colors.black54,
        title: Text(data.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: data.artist?.asText(),
      ),
      child: data.coverBytes == null
          ? const Center(child: Icon(Icons.music_note_rounded, size: 56))
          : Ink.image(image: MemoryImage(data.coverBytes!), fit: .cover),
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
            items: [
              PopupMenuItem(
                onTap: () async {
                  await project.delete();
                  onDelete?.call();
                },
                child: const Text('删除'),
              ),
            ],
          );
        },
        child: tile,
      ),
    );
  }
}
