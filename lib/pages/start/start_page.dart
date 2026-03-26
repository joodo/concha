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

  @override
  void initState() {
    super.initState();

    unawaited(_loadProjects());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: [
        Text(
          '我的曲库',
          style: theme.textTheme.displayMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ).padding(horizontal: 16.0, top: 16.0),
        if (_couldDisplayTile) _createDisplayTile(),
        _projects.isEmpty
            ? Text('暂无项目').center()
            : GridView.extent(
                maxCrossAxisExtent: 220,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: _projects
                    .sublist(_couldDisplayTile ? 1 : 0)
                    .map(
                      (project) => ProjectGridTile(
                        project: project,
                        onSelect: () => _pushRoute(project),
                        onDelete: _loadProjects,
                      ),
                    )
                    .toList(),
              ).expanded(),
      ].toColumn(crossAxisAlignment: .start),
      floatingActionButton: OpenContainer<Project?>(
        openBuilder: (context, _) => const NewDialog(),
        onClosed: (Project? project) {
          if (project == null) return;

          unawaited(_loadProjects());
          _pushRoute(project);
        },
        closedShape: const CircleBorder(),
        closedElevation: 6,
        closedColor: Theme.of(context).colorScheme.primary,
        openColor: Theme.of(context).scaffoldBackgroundColor,
        closedBuilder: (context, openContainer) {
          return FloatingActionButton(
            onPressed: openContainer,
            child: const Icon(Icons.add),
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
                Text(subtitle, maxLines: 1, overflow: .ellipsis),
              Text(
                project.summary!,
                maxLines: 4,
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
      onSecondaryTapDown: (details) {
        final o = details.globalPosition;
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(o.dx, o.dy, o.dx, o.dy),
          items: [
            PopupMenuItem(
              onTap: () async {
                await project.generateSummary();
                if (mounted) setState(() {});
              },
              child: '重新生成副标题'.asText(),
            ),
            PopupMenuItem(
              onTap: () async {
                await MvsepSeparationService.i.deleteCacheByAudioPath(
                  project.path.audio,
                );
                await project.delete();
                _loadProjects();
              },
              child: '删除'.asText(),
            ),
          ],
        );
      },
      child: themeWrap,
    );
  }

  bool get _couldDisplayTile => _projects.firstOrNull?.summary != null;
}
