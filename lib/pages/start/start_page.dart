import 'dart:async';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:styled_widget/styled_widget.dart';

import '/generated/l10n.dart';
import '/projects/projects.dart';
import '/utils/utils.dart';
import '/widgets/settings.dart';
import '/widgets/theme_from_image.dart';

import 'new_dialog.dart';
import 'project_grid_tile.dart';

class StartPage extends HookConsumerWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectListProvider);
    late final List<String> projectIds;
    switch (projectsAsync) {
      case AsyncData(:final value):
        projectIds = value;
      case AsyncError(:final error):
        return '${S.of(context).failedToLoad}: \n$error'.asText().center();
      case _:
        return CircularProgressIndicator().center();
    }

    final fabExpandedNotifier = useValueNotifier<bool>(true);

    final hasDisplayTile = _calcDisplayCardExistance(ref, projectIds);

    final gridProjects = projectIds.sublist(hasDisplayTile ? 1 : 0);

    final firstId = projectIds.firstOrNull;
    final displayCard = hasDisplayTile
        ? _DisplayCard(
            projectId: firstId!,
            onSelected: (project) => _pushRoute(context: context, id: firstId),
            onDelete: (projectId) =>
                _deleteProject(ref: ref, context: context, id: projectId),
          )
        : null;

    final scrollView = CustomScrollView(
      slivers: [
        _AppBar(displayCard: displayCard),
        if (projectIds.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: S.of(context).noProject.asText().center(),
          )
        else if (gridProjects.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate(
                gridProjects
                    .map(
                      (projectId) => ProjectGridTile(
                        projectId: projectId,
                        onSelect: () =>
                            _pushRoute(context: context, id: projectId),
                        onDelete: () => _deleteProject(
                          ref: ref,
                          context: context,
                          id: projectId,
                        ),
                      ),
                    )
                    .toList(),
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
            ),
          ),
      ],
    );

    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == .reverse) {
            fabExpandedNotifier.value = false;
          } else if (notification.direction == .forward) {
            fabExpandedNotifier.value = true;
          }
          return true;
        },
        child: scrollView,
      ),
      floatingActionButton: ValueListenableBuilder(
        valueListenable: fabExpandedNotifier,
        builder: (context, isExpanded, child) {
          return _FAB(
            isExpanded: isExpanded,
            onProjectCreated: (value) {
              ref.invalidate(projectListProvider);
              _pushRoute(context: context, id: value);
            },
          );
        },
      ),
    );
  }

  bool _calcDisplayCardExistance(WidgetRef ref, List<String> ids) {
    if (ids.isEmpty) return false;
    final firstId = ids.first;

    final project = ref.watch(projectDetailProvider(firstId)).value;
    if (project == null) return false;

    return project.summary != null;
  }

  void _pushRoute({required BuildContext context, required String id}) {
    Navigator.of(context).pushNamed('/project', arguments: {'id': id});
  }

  Future<void> _deleteProject({
    required WidgetRef ref,
    required BuildContext context,
    required String id,
  }) async {
    final action = ref.read(projectListProvider.notifier).dismiss(id);
    if (action == null) return;

    final controller = context.showSnackBar(
      SnackBar(
        content: S
            .of(context)
            .projectDeletedHint(action.value.metadata.title)
            .asText(),
        persist: false,
        action: SnackBarAction(
          label: S.of(context).undo,
          onPressed: action.undo,
        ),
      ),
    );

    final reason = await controller.closed;
    if (reason != SnackBarClosedReason.action) {
      await action.commit();
    }
  }
}

class _FAB extends StatelessWidget {
  const _FAB({required this.isExpanded, required this.onProjectCreated});

  final bool isExpanded;
  final ValueSetter<String> onProjectCreated;

  @override
  Widget build(BuildContext context) {
    return OpenContainer<Project?>(
      openBuilder: (context, _) => const NewDialog(),
      onClosed: (Project? project) {
        if (project == null) return;
        onProjectCreated(project.id);
      },
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
      ),
      closedColor: Colors.transparent,
      openColor: context.theme.scaffoldBackgroundColor,
      closedBuilder: (context, openContainer) => FloatingActionButton.extended(
        isExtended: isExpanded,
        onPressed: openContainer,
        label: S.of(context).addAudio.asText(),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.displayCard});

  final Widget? displayCard;

  @override
  Widget build(BuildContext context) {
    final hasDisplayTile = displayCard != null;

    final topPadding = MediaQuery.paddingOf(context).top;
    final expandedHeight = hasDisplayTile ? 330.0 : 150.0;

    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      expandedHeight: expandedHeight,
      actions: [const SettingButton().padding(right: 8.0)],
      titleSpacing: 16.0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final minHeight = kToolbarHeight + topPadding;
          final collapsibleRange = (expandedHeight - kToolbarHeight).clamp(
            1.0,
            double.infinity,
          );
          final currentHeight = (constraints.maxHeight - minHeight).clamp(
            0.0,
            collapsibleRange,
          );
          final t = (currentHeight / collapsibleRange).clamp(0.0, 1.0);
          final collapseProgress = 1.0 - t;
          final backgroundOpacity = (1.0 - (collapseProgress / 0.85)).clamp(
            0.0,
            1.0,
          );
          final titleOpacity = ((collapseProgress - 0.92) / 0.08).clamp(
            0.0,
            1.0,
          );

          return FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(
              start: 16.0,
              bottom: 16.0,
            ),
            title: IgnorePointer(
              child: Opacity(
                opacity: titleOpacity,
                child: S.of(context).myLibrary.asText(),
              ),
            ),
            collapseMode: .pin,
            background: SafeArea(
              bottom: false,
              child: [
                Opacity(
                  opacity: backgroundOpacity,
                  child: Text(
                    S.of(context).myLibrary,
                    style: context.textStyles.displayMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ).padding(horizontal: 16.0, top: 16.0),
                ),
                if (hasDisplayTile)
                  IgnorePointer(
                    ignoring: backgroundOpacity < 0.05,
                    child: Opacity(
                      opacity: backgroundOpacity,
                      child: displayCard,
                    ),
                  ),
              ].toColumn(crossAxisAlignment: .start),
            ),
          );
        },
      ),
    );
  }
}

class _DisplayCard extends ConsumerWidget {
  const _DisplayCard({
    required this.projectId,
    required this.onSelected,
    required this.onDelete,
  });

  final String projectId;
  final ValueSetter<Project> onSelected;
  final ValueSetter<String> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectDetailProvider(projectId)).value;
    if (project == null) return const SizedBox.shrink();

    final coverPath = project.path.cover;
    final metadata = project.metadata;
    final subtitle = [
      metadata.artist,
      metadata.album,
    ].whereType<String>().join(' - ');

    final content = Card(
      margin: EdgeInsets.all(16.0),
      clipBehavior: .hardEdge,
      elevation: 0,
      child: [
        Image.file(
          File(coverPath),
          fit: .cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.music_note_rounded, size: 56.0).center(),
        ).constrained(width: 240.0),
        [
              Text(
                metadata.title,
                style: context.textStyles.titleLarge,
                maxLines: 2,
              ),
              if (subtitle.isNotEmpty)
                Text(subtitle, maxLines: 3, overflow: .ellipsis),
              Text(
                project.summary!,
                maxLines: 3,
                overflow: .ellipsis,
              ).padding(top: 8.0),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => onSelected(project),
                child: S.of(context).continuePracticing.asText(),
              ),
            ]
            .toColumn(crossAxisAlignment: .start, mainAxisSize: .min)
            .padding(all: 12.0)
            .expanded(),
      ].toRow(),
    ).constrained(maxWidth: 600.0, height: 260.0);

    final themeWrap = ThemeFromImage(path: coverPath, child: content);

    return GestureDetector(
      onSecondaryTapDown: (details) =>
          context.showPopupMenu(details.globalPosition, [
            PopupMenuItem(
              onTap: ref
                  .read(projectDetailProvider(projectId).notifier)
                  .generateSummary,
              child: S.of(context).regenerateSubtitle.asText(),
            ),
            PopupMenuItem(
              onTap: () => onDelete(projectId),
              child: S.of(context).delete.asText(),
            ),
          ]),
      child: themeWrap,
    );
  }
}
