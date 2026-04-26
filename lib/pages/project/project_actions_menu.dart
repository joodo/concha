import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '/generated/l10n.dart';
import '/icon_font/icon_font.dart';
import '/lyric/lyric.dart';
import '/projects/projects.dart';
import '/utils/utils.dart';

import '../widgets/settings.dart';

import 'lyric_editing_dialog.dart';
import 'metadata_dialog.dart';

class ProjectActionsMenu extends ConsumerWidget {
  const ProjectActionsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuAnchor(
      builder: (context, controller, child) => IconButton(
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
        icon: const Icon(Icons.more_vert),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () async {
            final result = await showModal<MetadataEditingResult>(
              context: context,
              builder: (context) => MetadataDialog(project: ref.project!),
            );
            if (result == null) return;

            if (ref.project!.metadata != result.metadata) {
              ref.projectNotifier!.updateAndSave(
                (old) => old.copyWith(metadata: result.metadata),
              );
            }

            if (result.coverBytes != null) {
              await ref
                  .read(projectCoverBytesProvider(ref.projectId!).notifier)
                  .set(result.coverBytes!);
            }
          },
          leadingIcon: const Icon(UiIcons.disc),
          child: S.of(context).editMetadata.asText(),
        ),
        const Divider(),
        MenuItemButton(
          onPressed: () => _editLyric(ref, isTranslate: false),
          leadingIcon: const Icon(Icons.edit),
          child: S.of(context).editLyric.asText(),
        ),
        MenuItemButton(
          onPressed: () => _editLyric(ref, isTranslate: true),
          leadingIcon: const Icon(Icons.edit),
          child: S.of(context).editTranslateLyric.asText(),
        ),
        MenuItemButton(
          onPressed: ref.lyricNotifier(isTranslate: false)!.clearTemporarily,
          leadingIcon: const Icon(Icons.subtitles_off),
          child: S.of(context).clearLyric.asText(),
        ),
        const Divider(),
        MenuItemButton(
          onPressed: () => launchUrl(Uri.file(ref.project!.path.dir)),
          leadingIcon: const Icon(Icons.folder_open),
          child: S.of(context).openProjectDirectory.asText(),
        ),
        MenuItemButton(
          onPressed: () => showModal(
            context: context,
            builder: (context) => const Material(child: SettingDialog()),
          ),
          leadingIcon: const Icon(Icons.settings),
          child: S.of(context).settings.asText(),
        ),
      ],
    );
  }

  Future<void> _editLyric(WidgetRef ref, {required bool isTranslate}) async {
    final lrc = ref
        .read(lyricProvider(ref.projectId!, isTranslate: isTranslate))
        .value;

    final s = S.of(ref.context);
    final title =
        '${isTranslate ? s.editTranslateLyric : s.editLyric}: ${ref.project?.metadata.title}';
    final result = await showModal<String>(
      context: ref.context,
      builder: (context) =>
          LyricEditingDialog(initValue: lrc ?? '', title: title),
    );
    if (result == null || result == lrc) return;

    ref.lyricNotifier(isTranslate: isTranslate)!.save(result);
  }
}
