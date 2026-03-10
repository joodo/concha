import 'dart:io';

import 'package:animations/animations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../models/models.dart';
import '../../services/lyric_translation_service.dart';
import '../../utils/utils.dart';
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

  final _toolbarVisibleNotifier = ValueNotifier(false);

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
    _toolbarVisibleNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _lrc == null ? _buildEmptyContent() : _buildContent();

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

  Widget _buildContent() {
    return MouseRegion(
      onEnter: (event) => _toolbarVisibleNotifier.value = true,
      onExit: (event) => _toolbarVisibleNotifier.value = false,
      child: [
        _buildLyricView(),
        ValueListenableBuilder(
          valueListenable: _toolbarVisibleNotifier,
          builder: (context, visible, child) => Visibility(
            visible: visible,
            maintainState: true,
            child: IgnorePointer(
              ignoring: !visible,
              child: _buildLyricToolbar(),
            ),
          ),
        ).positioned(top: 12.0, left: 12.0),
      ].toStack(),
    );
  }

  Widget _buildLyricView() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return LyricView(
      controller: _lyricController,
      style: LyricStyles.default1.copyWith(
        textStyle: textTheme.titleLarge!.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        activeStyle: textTheme.displayMedium!.copyWith(
          shadows: [
            Shadow(
              blurRadius: 10,
              color: colorScheme.primaryContainer.withValues(alpha: 0.6),
            ),
          ],
        ),
        translationStyle: textTheme.titleMedium!.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        activeHighlightColor: colorScheme.primary,
        translationActiveColor: colorScheme.primary.withValues(alpha: 0.8),
        selectedColor: colorScheme.tertiary,
        selectedTranslationColor: colorScheme.tertiary.withValues(alpha: 0.8),
      ),
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildLyricToolbar() {
    return [
      _TranslateButton(onPressed: _createTranslate),
      IconButton.filledTonal(
        onPressed: () {
          setState(() {
            _lrc = null;
            _tlrc = null;
          });
        },
        icon: Icon(Icons.subtitles_off),
      ),
    ].toColumn(mainAxisSize: .min, separator: const SizedBox(height: 16.0));
  }

  void _updateLyricPosition() {
    _lyricController.setProgress(widget.playController.position);
  }

  Future<void> _createTranslate(String apiKey) async {
    _tlrc = await LyricTranslationService().translate(_lrc!, apiKey: apiKey);

    await File(widget.project.lyricTPath).writeAsString(_tlrc!);

    _updateLyric();
  }

  Future<void> _openLocalLyric() async {
    const XTypeGroup audioTypeGroup = XTypeGroup(
      label: '歌词文件',
      extensions: <String>['lrc'],
      mimeTypes: <String>['text/plain', 'application/octet-stream'],
    );

    final XFile? picked = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[audioTypeGroup],
    );
    if (picked == null) return;

    _lrc = await File(picked.path).readAsString();
    await File(widget.project.lyricPath).writeAsString(_lrc!);

    setState(() {
      _updateLyric();
    });
  }

  Future<void> _loadLyric() async {
    final lrcFile = File(widget.project.lyricPath);
    if (await lrcFile.exists()) {
      _lrc = await lrcFile.readAsString();
    }

    final tlrcFile = File(widget.project.lyricTPath);
    if (await tlrcFile.exists()) {
      _tlrc = await tlrcFile.readAsString();
    }

    setState(() {
      _updateLyric();
    });
  }

  void _updateLyric() {
    if (_lrc == null) return;
    _lyricController.loadLyric(_lrc!, translationLyric: _tlrc);
  }
}

class _TranslateButton extends StatefulWidget {
  final Future<void> Function(String apiKey)? onPressed;

  const _TranslateButton({this.onPressed});

  @override
  State<_TranslateButton> createState() => _TranslateButtonState();
}

class _TranslateButtonState extends State<_TranslateButton> {
  final _keyNotifier = PreferenceValueNotifier('', key: 'gemini_key');
  final _textController = TextEditingController();

  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _textController.text = _keyNotifier.value;
  }

  @override
  void dispose() {
    _keyNotifier.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: _isBusy
          ? null
          : () async {
              if (_keyNotifier.value.isEmpty) {
                _showTokenDialog();
              } else {
                setState(() {
                  _isBusy = true;
                });
                try {
                  await widget.onPressed?.call(_keyNotifier.value);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('翻译失败：$e')));
                  }
                } finally {
                  setState(() {
                    _isBusy = false;
                  });
                }
              }
            },
      onLongPress: _isBusy ? null : _showTokenDialog,
      icon: Icon(Icons.translate),
    );
  }

  void _showTokenDialog() async {
    await showModal(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini Api Key'),
        content: TextField(
          controller: _textController,
          onChanged: (value) => _keyNotifier.value = value,
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
