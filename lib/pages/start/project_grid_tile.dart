import 'dart:typed_data';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';

class ProjectGridTile extends StatefulWidget {
  const ProjectGridTile({required this.audioPath, this.onTap, super.key});

  final String audioPath;
  final VoidCallback? onTap;

  @override
  State<ProjectGridTile> createState() => _ProjectGridTileState();
}

class _ProjectGridTileState extends State<ProjectGridTile> {
  late Future<_ProjectTileViewData> _viewDataFuture;

  @override
  void initState() {
    super.initState();
    _viewDataFuture = _loadViewData();
  }

  @override
  void didUpdateWidget(covariant ProjectGridTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioPath != widget.audioPath) {
      _viewDataFuture = _loadViewData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProjectTileViewData>(
      future: _viewDataFuture,
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            _ProjectTileViewData(
              title: _fileNameFromPath(widget.audioPath),
              coverBytes: null,
            );

        return Material(
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: InkWell(
            onTap: widget.onTap,
            child: GridTile(
              footer: GridTileBar(
                backgroundColor: Colors.black54,
                title: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              child: data.coverBytes == null
                  ? const Center(
                      child: Icon(Icons.music_note_rounded, size: 56),
                    )
                  : Ink.image(
                      image: MemoryImage(data.coverBytes!),
                      fit: .cover,
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<_ProjectTileViewData> _loadViewData() async {
    final fallbackTitle = _fileNameFromPath(widget.audioPath);
    final file = File(widget.audioPath);

    if (!await file.exists()) {
      return _ProjectTileViewData(title: fallbackTitle, coverBytes: null);
    }

    try {
      final metadata = readMetadata(file, getImage: true);
      final title =
          _normalizeTitle((metadata as dynamic).title) ?? fallbackTitle;
      final coverBytes = _extractCoverBytes(metadata);
      return _ProjectTileViewData(title: title, coverBytes: coverBytes);
    } catch (_) {
      return _ProjectTileViewData(title: fallbackTitle, coverBytes: null);
    }
  }

  String _fileNameFromPath(String path) {
    final segments = Uri.file(path).pathSegments;
    if (segments.isEmpty) {
      return path;
    }
    return segments.last;
  }

  String? _normalizeTitle(dynamic rawTitle) {
    if (rawTitle is String) {
      final title = rawTitle.trim();
      return title.isEmpty ? null : title;
    }
    if (rawTitle is List && rawTitle.isNotEmpty) {
      final first = rawTitle.first;
      if (first is String) {
        final title = first.trim();
        return title.isEmpty ? null : title;
      }
    }
    return null;
  }

  Uint8List? _extractCoverBytes(dynamic metadata) {
    try {
      final pictures = (metadata as dynamic).pictures;
      if (pictures is! List || pictures.isEmpty) {
        return null;
      }

      final picture = pictures.first;
      final bytes = _readPictureBytes(picture);
      if (bytes != null && bytes.isNotEmpty) {
        return bytes;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Uint8List? _readPictureBytes(dynamic picture) {
    try {
      final rawBytes = (picture as dynamic).bytes;
      if (rawBytes is Uint8List) {
        return rawBytes;
      }
      if (rawBytes is List<int>) {
        return Uint8List.fromList(rawBytes);
      }
    } catch (_) {
      // Try an alternative field name used by some metadata implementations.
    }

    try {
      final rawData = (picture as dynamic).data;
      if (rawData is Uint8List) {
        return rawData;
      }
      if (rawData is List<int>) {
        return Uint8List.fromList(rawData);
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}

class _ProjectTileViewData {
  const _ProjectTileViewData({required this.title, required this.coverBytes});

  final String title;
  final Uint8List? coverBytes;
}
