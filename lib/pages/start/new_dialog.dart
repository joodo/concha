import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:path/path.dart' as p;
import 'package:styled_widget/styled_widget.dart';

import '/generated/l10n.dart';
import '/projects/projects.dart';
import '/services/services.dart';
import '/utils/utils.dart';
import '/widgets/settings.dart';

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
        labelText: S.of(context).selectAudioFile,
        hintText: S.of(context).supportAudioInputsHint,
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

    return Scaffold(
      appBar: AppBar(
        title: S.of(context).createNewProject.asText(),
        actions: [const SettingButton()],
        actionsPadding: EdgeInsets.symmetric(horizontal: 8.0),
      ),
      body:
          [
                audioField,
                FilledButton(
                  onPressed: isSubmitting.value ? null : submit,
                  child: Text(
                    isSubmitting.value
                        ? S.of(context).processing
                        : S.of(context).add,
                  ),
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
      throw (Exception(S.of(context).audioPathInvalidHint));
    }

    String audioPath = path;
    if (isYoutubeLink) {
      appendLog('[progress] Start downloading from YouTube...');
      audioPath = await YoutubeDownloadService().downloadAudio(
        url: path,
        onLog: appendLog,
      );
    }

    if (!context.mounted) return;
    appendLog('[progress] Start creating project...');
    final project = await _createProject(audioPath: audioPath);

    appendLog('[progress] All finished! Ready to leave.');
    if (context.mounted) Navigator.of(context).pop(project);
  }

  Future<Project> _createProject({required String audioPath}) async {
    // Create Metadata
    final m = readMetadata(File(audioPath), getImage: true);
    final filename = p.basenameWithoutExtension(audioPath);
    final metadata = Metadata(
      title: m.title ?? filename,
      artist: m.artist,
      album: m.album,
    );
    final coverBytes = m.pictures.firstOrNull?.bytes;

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

class _ConsoleArea extends HookWidget {
  const _ConsoleArea({required this.output});

  final String output;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    useEffect(() {
      runAfterBuild(() {
        if (!scrollController.hasClients) return;
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      });
      return null;
    }, [output]);

    return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            output.isEmpty ? 'Ready' : output,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        )
        .width(double.maxFinite)
        .border(color: context.theme.dividerColor, all: 1.0);
  }
}
