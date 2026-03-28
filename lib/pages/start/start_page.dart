import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:concha/helpers.dart';
import 'package:concha/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../models/models.dart';
import '../../services/services.dart';
import '../project/project_page.dart';
import 'new_dialog.dart';
import 'project_grid_tile.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final List<Project> _projects = [];

  final _fabExpandedNotifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();

    unawaited(_loadProjects());
  }

  @override
  void dispose() {
    _fabExpandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasDisplayTile = _couldDisplayTile;
    final gridProjects = _projects.sublist(hasDisplayTile ? 1 : 0);

    final scrollView = CustomScrollView(
      slivers: [
        _buildSliverAppBar(context),
        if (_projects.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Text('暂无项目').center(),
          )
        else if (gridProjects.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate(
                gridProjects
                    .map(
                      (project) => ProjectGridTile(
                        project: project,
                        onSelect: () => _pushRoute(project),
                        onDelete: () => _deleteProject(project),
                      ),
                    )
                    .toList(),
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
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
            _fabExpandedNotifier.value = false;
          } else if (notification.direction == .forward) {
            _fabExpandedNotifier.value = true;
          }
          return true;
        },
        child: scrollView,
      ),
      floatingActionButton: _createFAB(),
    );
  }

  OpenContainer<Project?> _createFAB() {
    Widget fabBuilder(BuildContext context, VoidCallback openContainer) {
      return ValueListenableBuilder(
        valueListenable: _fabExpandedNotifier,
        builder: (context, isExpanded, child) {
          return FloatingActionButton.extended(
            isExtended: isExpanded,
            onPressed: openContainer,
            label: '添加曲目'.asText(),
            icon: const Icon(Icons.add),
          );
        },
      );
    }

    return OpenContainer<Project?>(
      openBuilder: (context, _) => const NewDialog(),
      onClosed: (Project? project) {
        if (project == null) return;

        unawaited(_loadProjects());
        _pushRoute(project);
      },
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)), // M3 默认是 16.0
      ),
      closedColor: Colors.transparent,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      closedBuilder: fabBuilder,
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final hasDisplayTile = _couldDisplayTile;
    final expandedHeight = hasDisplayTile ? 330.0 : 150.0;

    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      expandedHeight: expandedHeight,
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
            title: Opacity(opacity: titleOpacity, child: Text('我的曲库')),
            collapseMode: .pin,
            background: SafeArea(
              bottom: false,
              child: [
                Opacity(
                  opacity: backgroundOpacity,
                  child: Text(
                    '我的曲库',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ).padding(horizontal: 16.0, top: 16.0),
                ),
                if (hasDisplayTile)
                  IgnorePointer(
                    ignoring: backgroundOpacity < 0.05,
                    child: Opacity(
                      opacity: backgroundOpacity,
                      child: _createDisplayTile(),
                    ),
                  ),
              ].toColumn(crossAxisAlignment: .start),
            ),
          );
        },
      ),
    );
  }

  void _pushRoute(Project project) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ProjectPage(project: project)),
    );
  }

  Future<void> _loadProjects() async {
    final directory = Directory(Project.savedDir);
    final entries = await directory
        .list()
        .map((entity) {
          final infoPath = '${entity.path}${Platform.pathSeparator}info.json';
          return File(infoPath);
        })
        .where((entity) => entity.existsSync())
        .cast<File>()
        .toList();

    final projectsWithMtime = <MapEntry<Project, DateTime>>[];

    for (final file in entries) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final project = Project.fromJson(json);
        final modifiedAt = await file.lastModified();
        projectsWithMtime.add(MapEntry(project, modifiedAt));
      } catch (_) {
        // Ignore malformed files and continue loading valid projects.
      }
    }

    projectsWithMtime.sort((a, b) => b.value.compareTo(a.value));

    if (!mounted) {
      return;
    }

    setState(() {
      _projects
        ..clear()
        ..addAll(projectsWithMtime.map((entry) => entry.key));
    });
  }

  Widget _createDisplayTile() {
    final project = _projects.first;

    final coverFile = File(project.path.cover);
    final metadata = project.metadata;
    final subtitle = [
      metadata.artist,
      metadata.album,
    ].whereType<String>().join(' - ');

    final textStyles = Theme.of(context).textTheme;
    final content = Card(
      margin: EdgeInsets.all(16.0),
      clipBehavior: .hardEdge,
      elevation: 0,
      child: [
        Image.file(
          coverFile,
          fit: .cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.music_note_rounded, size: 56.0).center(),
        ).constrained(width: 240.0),
        [
              Text(metadata.title, style: textStyles.titleLarge, maxLines: 2),
              if (subtitle.isNotEmpty)
                Text(subtitle, maxLines: 3, overflow: .ellipsis),
              Text(
                project.summary!,
                maxLines: 3,
                overflow: .ellipsis,
              ).padding(top: 8.0),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () => _pushRoute(project),
                child: '继续'.asText(),
              ),
            ]
            .toColumn(crossAxisAlignment: .start, mainAxisSize: .min)
            .padding(all: 12.0)
            .expanded(),
      ].toRow(),
    ).constrained(maxWidth: 600.0, height: 260.0);

    final themeWrap = FutureBuilder(
      future: ColorScheme.fromImageProvider(provider: FileImage(coverFile)),
      initialData: Theme.of(context).colorScheme,
      builder: (context, snapshot) => Theme(
        data: Theme.of(context).copyWith(colorScheme: snapshot.data),
        child: content,
      ),
    );

    return GestureDetector(
      onSecondaryTapDown: (details) =>
          context.showPopupMenu(details.globalPosition, [
            PopupMenuItem(
              onTap: () async {
                await project.generateSummary();
                if (mounted) setState(() {});
              },
              child: '重新生成副标题'.asText(),
            ),
            PopupMenuItem(
              onTap: () => _deleteProject(project),
              child: '删除'.asText(),
            ),
          ]),
      child: themeWrap,
    );
  }

  bool get _couldDisplayTile => _projects.firstOrNull?.summary != null;

  Future<void> _deleteProject(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    setState(() {
      _projects.removeAt(index);
    });

    final controller = context.showSnackBar(
      SnackBar(
        content: '已删除 ${project.metadata.title}'.asText(),
        persist: false,
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => setState(() {
            _projects.insert(index, project);
          }),
        ),
      ),
    );

    final reason = await controller.closed;
    if (reason != SnackBarClosedReason.action) {
      await MvsepSeparationService.i.deleteCacheByAudioPath(project.path.audio);
      await project.delete();
    }
  }
}
