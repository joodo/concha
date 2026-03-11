import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:path/path.dart' as p;

import '../../models/models.dart';
import '../../services/media_match_service.dart';
import '../../services/youtube_download_service.dart';
import '../../utils/utils.dart';
import '../../widgets/setting_button.dart';

class NewDialog extends StatefulWidget {
  const NewDialog({super.key});

  @override
  State<NewDialog> createState() => _NewDialogState();
}

class _NewDialogState extends State<NewDialog> {
  final _mediaMatchService = MediaMatchService();
  final _youtubeDownloadService = YoutubeDownloadService();
  final _audioFieldController = TextEditingController();

  final _fillDataNotifier = PreferenceValueNotifier<bool>(
    true,
    key: PrefKeys.autoFillMetadata.value,
  );

  bool _isSubmitting = false;
  String? _errorMessage;
  String _shellOutput = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _audioFieldController.dispose();
    _fillDataNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioField = TextField(
      controller: _audioFieldController,
      decoration: InputDecoration(
        labelText: '选择音频文件',
        hintText: '支持 Youtube 链接或本地文件',
        errorText: _errorMessage,
        suffix: IconButton(
          onPressed: _openLocal,
          icon: Icon(Icons.folder_open),
        ),
      ),
      onSubmitted: (_) => _submit(),
    );

    final fillDataTile = ListenableBuilder(
      listenable: _fillDataNotifier,
      builder: (context, _) => CheckboxListTile(
        title: const Text('补全音乐信息'),
        controlAffinity: ListTileControlAffinity.leading,
        value: _fillDataNotifier.value,
        onChanged: (value) => _fillDataNotifier.value = value!,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('新建项目'),
        actions: [const SettingButton()],
        actionsPadding: EdgeInsets.symmetric(horizontal: 8.0),
      ),
      body:
          [
                audioField,
                fillDataTile,
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(_isSubmitting ? '处理中...' : '添加'),
                ),
                _ConsoleArea(output: _shellOutput).expanded(),
              ]
              .toColumn(
                crossAxisAlignment: .start,
                separator: const SizedBox(height: 16),
              )
              .padding(all: 16.0),
    );
  }

  Future<void> _openLocal() async {
    const XTypeGroup audioTypeGroup = XTypeGroup(
      label: 'audio',
      extensions: <String>['mp3', 'm4a', 'wav', 'flac', 'aac', 'ogg'],
    );

    final XFile? picked = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[audioTypeGroup],
    );
    if (picked == null) return;

    _audioFieldController.text = picked.path;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final path = _audioFieldController.text.trim();

    final isYoutubeLink = _isYoutubeLink(path);
    final isLocalFile = path.isNotEmpty && File(path).existsSync();
    if (!isYoutubeLink && !isLocalFile) {
      setState(() => _errorMessage = '请输入本地音频文件路径或有效的 YouTube 链接');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _shellOutput = '';
      _errorMessage = null;
    });

    try {
      String audioPath = path;
      if (isYoutubeLink) {
        _appendLog('[progress] Start downloading from YouTube...');
        audioPath = await _youtubeDownloadService.downloadAudio(
          url: path,
          onLog: _appendLog,
        );
      }

      MediaMatchResult? mediaData;
      if (_fillDataNotifier.value) {
        _appendLog('[progress] Start matching metadata...');
        mediaData = await _getMatchedMedia(audioPath);
      }

      if (!mounted) return;
      _appendLog('[progress] Start creating project...');
      final project = await _createProject(
        audioPath: audioPath,
        matchedMediaInfo: mediaData,
      );

      _appendLog('[progress] All finished! Ready to leave.');
      if (mounted) Navigator.of(context).pop(project);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<MediaMatchResult?> _getMatchedMedia(String path) async {
    return _mediaMatchService.identifyByAudioPath(
      audioPath: path,
      onLog: _appendLog,
    );
  }

  Future<Project> _createProject({
    required String audioPath,
    MediaMatchResult? matchedMediaInfo,
  }) async {
    // Create Metadata
    late final Uint8List? coverBytes;
    late final Metadata metadata;
    if (matchedMediaInfo != null) {
      metadata = Metadata(
        title: matchedMediaInfo.title,
        artist: matchedMediaInfo.artist,
        album: matchedMediaInfo.album,
      );
      coverBytes = matchedMediaInfo.coverBytes;
    } else {
      final m = readMetadata(File(audioPath), getImage: true);
      final filename = p.basenameWithoutExtension(audioPath);
      metadata = Metadata(
        title: m.title ?? filename,
        artist: m.artist,
        album: m.album,
      );
      coverBytes = m.pictures.firstOrNull?.bytes;
    }

    // Create project
    final project = Project(metadata: metadata);
    await project.save();

    // Copy audio file
    final sourceFile = File(audioPath);
    await sourceFile.copy(project.path.audio);
    if (await isInTemporaryDirectory(audioPath)) await sourceFile.delete();

    // Create cover file
    if (coverBytes != null) {
      await File(project.path.cover).writeAsBytes(coverBytes);
    }

    return project;
  }

  void _appendLog(String line) {
    if (!mounted) return;
    setState(() {
      _shellOutput = _shellOutput.isEmpty ? '$line\n' : '$_shellOutput$line\n';
    });
  }

  bool _isYoutubeLink(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    if (!uri.hasScheme) return false;
    if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
      return false;
    }

    final host = uri.host.toLowerCase();
    return host == 'youtu.be' ||
        host == 'youtube.com' ||
        host.endsWith('.youtube.com');
  }
}

class _ConsoleArea extends StatefulWidget {
  const _ConsoleArea({required this.output});

  final String output;

  @override
  State<_ConsoleArea> createState() => _ConsoleAreaState();
}

class _ConsoleAreaState extends State<_ConsoleArea> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ConsoleArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.output == oldWidget.output) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            widget.output.isEmpty ? '暂无输出' : widget.output,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        )
        .width(double.maxFinite)
        .border(color: Theme.of(context).dividerColor, all: 1.0);
  }
}
