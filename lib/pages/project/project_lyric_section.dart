import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../models/models.dart';
import '../../play_controller.dart';

class ProjectLyricSection extends StatefulWidget {
  const ProjectLyricSection({
    super.key,
    required this.project,
    required this.playController,
  });

  final Project project;
  final PlayController playController;

  @override
  State<ProjectLyricSection> createState() => _ProjectLyricSectionState();
}

class _ProjectLyricSectionState extends State<ProjectLyricSection> {
  final _lyricController = LyricController();

  String? _lrc, _tlrc;

  @override
  void initState() {
    super.initState();

    widget.playController.addListener(_updateLyricPosition);
    _loadLyric();
  }

  @override
  void dispose() {
    widget.playController.removeListener(_updateLyricPosition);
    _lyricController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme;
    final content = _lrc == null
        ? _buildEmptyContent()
        : LyricView(
            controller: _lyricController,
            style: LyricStyles.default1.copyWith(
              textStyle: textStyle.headlineSmall!.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              activeStyle: textStyle.displayMedium!.copyWith(
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                  ),
                ],
              ),
              translationStyle: TextStyle(fontSize: 13),
              activeHighlightColor: colorScheme.primary,
              selectedColor: colorScheme.tertiary,
            ),
            width: double.infinity,
            height: double.infinity,
          );

    final coverBytes = widget.project.metadata.coverBytes;
    return [
      if (coverBytes != null) Image.memory(coverBytes, fit: .cover),
      content
          .backgroundBlur(10.0)
          .backgroundColor(
            Theme.of(context).colorScheme.surfaceContainerLow.withAlpha(180),
          ),
    ].toStack(fit: .expand);
  }

  Widget _buildEmptyContent() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: .hardEdge,
      color: colorScheme.primaryContainer,
      child: InkWell(
        onTap: _openLocalLyric,
        child:
            [
                  Icon(
                    Icons.folder_open,
                    size: 48.0,
                    color: colorScheme.secondary,
                  ),
                  Text('打开本地歌词', style: Theme.of(context).textTheme.bodyLarge),
                ]
                .toColumn(
                  mainAxisSize: .min,
                  separator: const SizedBox(height: 8.0),
                )
                .padding(all: 16.0),
      ),
    ).center();
  }

  void _updateLyricPosition() {
    _lyricController.setProgress(widget.playController.position);
  }

  Future<void> _openLocalLyric() async {
    const XTypeGroup audioTypeGroup = XTypeGroup(
      label: '歌词文件',
      extensions: <String>['lrc'],
      mimeTypes: <String>[
        'text/plain',
        'application/octet-stream',
      ], // 部分系统将lrc识别为纯文本
    );

    final XFile? picked = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[audioTypeGroup],
    );
    if (picked == null) return;

    final lrc = await File(picked.path).readAsString();

    await File(widget.project.lyricPath).writeAsString(lrc);
    setState(() {
      _setLyric(lrc);
    });
  }

  Future<void> _loadLyric() async {
    final lrcFile = File(widget.project.lyricPath);
    if (await lrcFile.exists()) {
      final lrc = await lrcFile.readAsString();
      setState(() {
        _setLyric(lrc);
      });
    }
  }

  void _setLyric(String lrc) {
    _lrc = lrc;
    _lyricController.loadLyric(lrc);
  }
}
