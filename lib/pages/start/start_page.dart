import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../models/models.dart';
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
        ).padding(all: 16.0),
        _projects.isEmpty
            ? Text('暂无项目').center()
            : GridView.extent(
                maxCrossAxisExtent: 220,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: _projects
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
}
