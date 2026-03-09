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
    return Scaffold(
      body: _projects.isEmpty
          ? Text('暂无项目').center()
          : GridView.extent(
              maxCrossAxisExtent: 220,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: _projects
                  .map(
                    (project) => ProjectGridTile(
                      audioPath: project.audioPath,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProjectPage(project: project),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
      floatingActionButton: OpenContainer<String?>(
        openBuilder: (context, _) => const NewDialog(),
        onClosed: (String? id) {
          if (id != null) {
            _projectCreated(id);
          }
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

  void _projectCreated(String id) {
    unawaited(_loadProjects());
  }

  Future<void> _loadProjects() async {
    final savedDir = await Project.savedDir;
    final directory = Directory(savedDir);
    final entries = await directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
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
