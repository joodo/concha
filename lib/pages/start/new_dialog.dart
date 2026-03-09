import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../models/models.dart';

class NewDialog extends StatefulWidget {
  const NewDialog({super.key});

  @override
  State<NewDialog> createState() => _NewDialogState();
}

class _NewDialogState extends State<NewDialog> {
  final TextEditingController _audioController = TextEditingController();

  @override
  void dispose() {
    _audioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建项目')),
      body: [
        TextField(
          controller: _audioController,
          decoration: InputDecoration(
            labelText: '选择音频文件',
            suffix: IconButton(
              onPressed: _openLocal,
              icon: Icon(Icons.folder_open),
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        //ElevatedButton(onPressed: _submit, child: const Text('Confirm')),
      ].toColumn().padding(all: 16.0),
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
    if (picked == null) {
      return;
    }
    final Project project = Project(audioPath: picked.path);
    await project.save();

    if (!mounted) return;
    Navigator.of(context).pop(project.id);
  }

  void _submit() {
    final path = _audioController.text.trim();
    throw UnimplementedError(path);
  }
}
