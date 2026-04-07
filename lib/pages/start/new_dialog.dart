import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:styled_widget/styled_widget.dart';

import '/preferences/preferences.dart';
import '/projects/projects.dart';
import '/services/services.dart';
import '/utils/utils.dart';
import '/widgets/setting_button.dart';

class NewDialog extends HookWidget {
  const NewDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final errorMessage = useState<String?>(null);
    final isSubmitting = useState<bool>(false);

    final shellOutput = useState<String>('');
    final appendLog = useCallback((String line) {
      if (!context.mounted) return;
      shellOutput.value += '$line\n';
    });

    final audioFieldController = useTextEditingController();
    final submit = useCallback(() async {
      shellOutput.value = '';
      errorMessage.value = null;
      isSubmitting.value = true;
      try {
        await _submit(
          context,
          audioFieldController.text.trim(),
          appendLog: appendLog,
        );
      } catch (e) {
        errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      } finally {
        isSubmitting.value = false;
      }
    });

    final audioField = TextField(
      controller: audioFieldController,
      decoration: InputDecoration(
        labelText: '选择音频文件',
        hintText: '支持 Youtube 链接或本地文件',
        errorText: errorMessage.value,
        suffix: IconButton(
          onPressed: () async {
            final path = await _getLocalPath();
            if (path != null) audioFieldController.text = path;
          },
          icon: Icon(Icons.folder_open),
        ),
      ),
      onSubmitted: (_) => submit(),
    );

    final fillDataTile = Consumer(
      builder: (context, ref, child) {
        final provider = preferenceProvider<bool>(.autoFillMetadata);
        return CheckboxListTile(
          title: const Text('补全音乐信息'),
          controlAffinity: ListTileControlAffinity.leading,
          value: ref.watch(provider)!,
          onChanged: (value) => ref.read(provider.notifier).set(value!),
        );
      },
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
                  onPressed: isSubmitting.value ? null : submit,
                  child: Text(isSubmitting.value ? '处理中...' : '添加'),
                ),
                _ConsoleArea(output: shellOutput.value).expanded(),
              ]
              .toColumn(
                crossAxisAlignment: .start,
                separator: const SizedBox(height: 16),
              )
              .padding(all: 16.0),
    );
  }

  Future<String?> _getLocalPath() async {
    const XTypeGroup audioTypeGroup = XTypeGroup(
      label: 'audio',
      extensions: <String>['mp3', 'm4a', 'wav', 'flac', 'aac', 'ogg'],
    );

    final XFile? picked = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[audioTypeGroup],
    );
    return picked?.path;
  }

  Future<void> _submit(
    BuildContext context,
    String path, {
    required ValueSetter<String> appendLog,
  }) async {
    path = path.trim();
    final isYoutubeLink = _isYoutubeLink(path);
    final isLocalFile = path.isNotEmpty && File(path).existsSync();
    if (!isYoutubeLink && !isLocalFile) {
      throw (Exception('请输入本地音频文件路径或有效的 YouTube 链接'));
    }

    String audioPath = path;
    if (isYoutubeLink) {
      appendLog('[progress] Start downloading from YouTube...');
      audioPath = await YoutubeDownloadService().downloadAudio(
        url: path,
        onLog: appendLog,
      );
    }

    MediaMatchResult? mediaData;
    appendLog('[progress] Start matching metadata...');
    mediaData = await MediaMatchService().identifyByAudioPath(
      audioPath: audioPath,
      onLog: appendLog,
    );

    if (!context.mounted) return;
    appendLog('[progress] Start creating project...');
    final project = await _createProject(
      audioPath: audioPath,
      matchedMediaInfo: mediaData,
    );

    appendLog('[progress] All finished! Ready to leave.');
    if (context.mounted) Navigator.of(context).pop(project);
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
