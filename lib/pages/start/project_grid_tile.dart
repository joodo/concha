import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/generated/l10n.dart';
import '/projects/riverpod.dart';
import '/utils/utils.dart';

import '../widgets/album_cover_placeholder.dart';

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
    final coverBytes = ref.watch(projectCoverBytesProvider(projectId)).value;

    final tile = GridTile(
      footer: GridTileBar(
        backgroundColor: Colors.black54,
        title: Text(data.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: data.artist?.asText(),
      ),
      child: coverBytes != null
          ? Ink.image(image: MemoryImage(coverBytes), fit: .cover)
          : const AlbumCoverPlaceholder(),
    );

    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onSelect,
        onSecondaryTapDown: (details) =>
            context.showPopupMenu(details.globalPosition, [
              PopupMenuItem(
                onTap: onDelete,
                child: S.of(context).delete.asText(),
              ),
            ]),
        child: tile,
      ),
    );
  }
}
