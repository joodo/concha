import 'dart:io';

import 'package:animations/animations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:styled_widget/styled_widget.dart';

import '/adaptive_widgets/adaptive_widgets.dart';
import '/generated/l10n.dart';
import '/lyric/lyric.dart';
import '/network/network.dart';
import '/preferences/preferences.dart';
import '/projects/projects.dart';
import '/services/services.dart';
import '/utils/utils.dart';

import '../widgets/album_cover_placeholder.dart';
import '../widgets/settings.dart';

class ProjectActionsMenu extends ConsumerWidget {
  const ProjectActionsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuAnchor(
      builder: (context, controller, child) => IconButton(
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
        icon: const Icon(Icons.more_vert),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () async {
            final result = await showModal<_MetadataEditResult>(
              context: context,
              builder: (context) => _MetadataDialog(project: ref.project!),
            );
            if (result == null) return;

            if (ref.project!.metadata != result.metadata) {
              ref.projectNotifier!.updateAndSave(
                (old) => old.copyWith(metadata: result.metadata),
              );
            }

            if (result.coverBytes != null) {
              await ref
                  .read(projectCoverBytesProvider(ref.projectId!).notifier)
                  .set(result.coverBytes!);
            }
          },
          leadingIcon: const FaIcon(FontAwesomeIcons.compactDisc),
          child: S.of(context).editMetadata.asText(),
        ),
        const Divider(),
        MenuItemButton(
          onPressed: () => _editLyric(ref, isTranslate: false),
          leadingIcon: const Icon(Icons.edit),
          child: S.of(context).editLyric.asText(),
        ),
        MenuItemButton(
          onPressed: () => _editLyric(ref, isTranslate: true),
          leadingIcon: const Icon(Icons.edit),
          child: S.of(context).editTranslateLyric.asText(),
        ),
        MenuItemButton(
          onPressed: ref.lyricNotifier(isTranslate: false)!.clearTemporarily,
          leadingIcon: const Icon(Icons.subtitles_off),
          child: S.of(context).clearLyric.asText(),
        ),
        const Divider(),
        MenuItemButton(
          onPressed: () => showModal(
            context: context,
            builder: (context) => const Material(child: SettingDialog()),
          ),
          leadingIcon: const Icon(Icons.settings),
          child: S.of(context).settings.asText(),
        ),
      ],
    );
  }

  Future<void> _editLyric(WidgetRef ref, {required bool isTranslate}) async {
    final lrc = ref
        .read(lyricProvider(ref.projectId!, isTranslate: isTranslate))
        .value;

    final s = S.of(ref.context);
    final title =
        '${isTranslate ? s.editTranslateLyric : s.editLyric}: ${ref.project?.metadata.title}';
    final result = await showModal<String>(
      context: ref.context,
      builder: (context) =>
          _LyricEditDialog(initValue: lrc ?? '', title: title),
    );
    if (result == lrc) return;

    ref.lyricNotifier(isTranslate: isTranslate)!.save(result!);
  }
}

typedef _SearchResult = ({
  String title,
  String? artist,
  String? album,
  Uri coverUrl,
});

typedef _MetadataEditResult = ({Metadata metadata, Uint8List? coverBytes});

class _MetadataDialog extends HookWidget {
  const _MetadataDialog({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    final textControllers = (
      title: useTextEditingController(text: project.metadata.title),
      artist: useTextEditingController(text: project.metadata.artist),
      album: useTextEditingController(text: project.metadata.album),
    );

    final coverUri = useState<Uri>(Uri.file(project.path.cover));

    final searchFuture = useState<Future<List<_SearchResult>>>(
      Future.value([]),
    );
    final searchResult = useFuture<List<_SearchResult>>(
      searchFuture.value,
      preserveState: false,
    );

    final acoustProgress = useValueNotifier<String?>(null);

    final searchSectionKey = useGlobalKey();

    final albumCover = [
      Consumer(
            builder: (context, ref, child) {
              if (coverUri.value.isScheme('file')) {
                return Image.file(
                  File(coverUri.value.toFilePath()),
                  errorBuilder: (context, error, stackTrace) =>
                      const AlbumCoverPlaceholder(),
                );
              } else {
                final blob = ref.watch(httpBlobProvider(coverUri.value)).value;

                return blob == null
                    ? const AlbumCoverPlaceholder()
                    : Image.memory(blob);
              }
            },
          )
          .center()
          .backgroundColor(context.colors.surfaceContainer)
          .clipRRect(all: 16.0)
          .padding(all: 8.0),
      IconButton.filled(
        onPressed: () async {
          final path = await _getImagePath(S.of(context).imageFile);
          if (path == null) return;
          coverUri.value = Uri.file(path);
        },
        icon: Icon(Icons.add),
      ).positioned(right: 0, bottom: 0),
    ].toStack().aspectRatio(aspectRatio: 1.0);

    final metadataForm = [
      TextField(
        decoration: InputDecoration(
          labelText: S.of(context).title,
          border: const OutlineInputBorder(),
        ),
        controller: textControllers.title,
      ),
      TextField(
        decoration: InputDecoration(
          labelText: S.of(context).album,
          border: const OutlineInputBorder(),
        ),
        controller: textControllers.album,
      ),
      TextField(
        decoration: InputDecoration(
          labelText: S.of(context).artist,
          border: const OutlineInputBorder(),
        ),
        controller: textControllers.artist,
      ),
    ].toColumn(crossAxisAlignment: .stretch, separator: 16.0.asHeight());

    return AdaptiveLayoutBuilder(
      builder: (context, layoutSize) {
        final searchActions = [
          FilledButton.icon(
            onPressed: searchResult.connectionState == .waiting
                ? null
                : () {
                    searchFuture.value = _searchMetadata(
                      title: textControllers.title.text,
                      artist: textControllers.artist.text,
                      album: textControllers.album.text,
                    );
                  },
            label: S.of(context).searchOnline.asText(),
            icon: Icon(Icons.search),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.tertiaryContainer,
              foregroundColor: context.colors.onTertiaryContainer,
            ),
          ),
          FilledButton.icon(
            onPressed: searchResult.connectionState == .waiting
                ? null
                : () {
                    searchFuture.value = AcoustIdService()
                        .recognizeLocalFile(
                          audioFilePath: project.path.audio,
                          apiKey: Pref.get(.acoustKey),
                          onProgress: acoustProgress.set,
                        )
                        .then((result) {
                          acoustProgress.clear();
                          return result;
                        });
                  },
            label: 'Voice ID'.asText(),
            icon: Icon(Icons.fingerprint),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.tertiaryContainer,
              foregroundColor: context.colors.onTertiaryContainer,
            ),
          ),
          ValueListenableBuilder(
            valueListenable: acoustProgress,
            builder: (context, value, child) => (value ?? '').asText(),
          ),
        ].toRow(separator: 12.0.asWidth()).padding(horizontal: 16.0);
        final searchResultView = Builder(
          builder: (context) {
            if (searchResult.data?.isEmpty == true) {
              return S
                  .of(context)
                  .noMediaInformationFound
                  .asText()
                  .textColor(context.colors.onSurfaceVariant)
                  .center();
            }

            if (searchResult.hasError) {
              return searchResult.error.toString().asText().center();
            }

            final data =
                searchResult.data ??
                List.filled(6, (
                  title: 'Mock Title',
                  artist: 'Mock Artist',
                  album: 'Mock Album',
                  coverUrl: Uri.parse('http://www.example.com'),
                ));

            final listView = AdaptiveListView(
              isList: layoutSize.breakPoint <= .medium,
              onTap: (value) {
                textControllers.title.text = value.title;
                textControllers.album.text = value.album ?? '';
                textControllers.artist.text = value.artist ?? '';
                coverUri.value = value.coverUrl;
              },
              imageBuilder: (context, data, useList) => Consumer(
                builder: (context, ref, child) {
                  final placeholder = Ink(
                    color: context.colors.surfaceContainerHigh,
                    child: Icon(
                      Icons.music_note_rounded,
                      size: useList ? 32.0 : 56.0,
                    ).center(),
                  );

                  if (data.coverUrl.host == 'www.example.com') {
                    return placeholder;
                  }

                  final blob = ref.watch(httpBlobProvider(data.coverUrl));
                  return switch (blob) {
                    AsyncLoading() => Skeletonizer.zone(
                      child: Bone.square(size: 48.0),
                    ),
                    AsyncData(:final value) => Ink.image(
                      image: MemoryImage(value),
                    ),
                    AsyncError() => placeholder,
                  };
                },
              ).aspectRatio(aspectRatio: 1.0),
              titleBuilder: (context, data, useList) => data.title.asText(),
              subtitleBuilder: (context, data, useList) {
                final (:title, :artist, :album, :coverUrl) = data;
                return [
                  ?artist,
                  if (artist != null && album != null) ' - ',
                  ?album,
                ].map((e) => e.asText()).toList().toWrap();
              },
              data: data,
            );
            return Skeletonizer(
              enabled: !searchResult.hasData,
              enableSwitchAnimation: true,
              child: listView,
            );
          },
        );
        final searchSection = [searchActions, searchResultView.expanded()]
            .toColumn(
              key: searchSectionKey,
              crossAxisAlignment: .stretch,
              separator: 8.0.asHeight(),
            );

        final Axis bodyDirection = layoutSize.breakPoint >= .expanded
            ? .horizontal
            : .vertical;

        final saveButton = Consumer(
          builder: (context, ref, child) => FilledButton(
            onPressed: () async {
              final metadata = Metadata(
                title: textControllers.title.text,
                album: textControllers.album.text.nullIfEmpty,
                artist: textControllers.artist.text.nullIfEmpty,
              );

              final uri = coverUri.value;
              final coverBytes = uri == Uri.file(project.path.audio)
                  ? null
                  : uri.isScheme('file')
                  ? await File(uri.toFilePath()).readAsBytes()
                  : await ref.read(httpBlobProvider(uri).future);

              if (!context.mounted) return;
              Navigator.of(context).maybePop<_MetadataEditResult>((
                metadata: metadata,
                coverBytes: coverBytes,
              ));
            },
            child: S.of(context).save.asText(),
          ),
        );

        final metadataSection = switch (layoutSize.breakPoint) {
          SizeBreakPoint.compact => [
            albumCover.constrained(width: 200.0),
            metadataForm,
          ].toColumn(separator: 8.0.asHeight()),
          SizeBreakPoint.medium => [
            albumCover.constrained(width: 200.0),
            metadataForm.expanded(),
          ].toRow(separator: 8.0.asWidth()),
          >= SizeBreakPoint.expanded => [
            albumCover.padding(horizontal: 56.0, bottom: 12.0),
            metadataForm,
            saveButton.padding(top: 12.0),
          ].toColumn(crossAxisAlignment: .stretch, separator: 8.0.asHeight()),
          _ => throw UnimplementedError(),
        };

        final appBar = AppBar(
          leading: const CloseButton(),
          title: S.of(context).editMetadata.asText(),
          centerTitle: false,
          actions: bodyDirection == .vertical
              ? [saveButton, 16.0.asWidth()]
              : null,
          notificationPredicate: (notification) => false,
        );

        final content = layoutSize.breakPoint <= .medium
            ? Scaffold(
                appBar: appBar,
                body: [
                  metadataSection.padding(horizontal: 12.0),
                  searchSection.expanded(),
                ].toColumn(separator: 16.0.asHeight()),
              )
            : [
                Scaffold(
                  appBar: appBar,
                  body: metadataSection.padding(horizontal: 12.0),
                ).constrained(maxWidth: 500.0).flexible(flex: 3),
                searchSection.padding(top: 16.0).expanded(flex: 5),
              ].toRow(separator: 16.0.asWidth());

        final popScope = PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            if (result != null) return Navigator.of(context).pop(result);

            final discard = await showModal<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: S.of(context).discardChanges.asText(),
                content: S
                    .of(context)
                    .metadataWillBeRestoredToTheStateBeforeModification
                    .asText()
                    .constrained(maxWidth: 400.0),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: S.of(context).cancel.asText(),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: S.of(context).discard.asText(),
                  ),
                ],
              ),
            );

            if (context.mounted && discard == true) Navigator.of(context).pop();
          },
          child: content,
        );

        return AdaptiveDialog(
          isFullscreen: layoutSize.breakPoint <= .medium,
          backgroundColor: context.colors.surfaceContainerLow,
          child: popScope,
        );
      },
    );
  }

  Future<List<_SearchResult>> _searchMetadata({
    required String title,
    required String artist,
    required String album,
  }) async {
    final args = [
      ('recording', title.trim()),
      ('artistname', artist.trim()),
      ('release', album.trim()),
    ];
    String query = args
        .where((e) => e.$2.isNotEmpty)
        .map((e) => '${e.$1}:"${e.$2}"')
        .join(' AND ');
    query = '($query)';

    final response = await http()
        .headers(const {
          'Accept': 'application/json',
          'User-Agent': 'Concha/0.0.1 (music metadata resolver)',
        })
        .get(
          'https://musicbrainz.org/ws/2/recording',
          queryParameters: {'query': query, 'limit': 50, 'fmt': 'json'},
        );

    final recordings = response.data['recordings'] as List?;
    if (recordings == null) return [];

    final results = recordings
        .map(
          (e) => (
            title: e['title'] as String,
            releases: e['releases'] as List? ?? [],
          ),
        )
        .expand(
          (e) => e.releases.map(
            (release) => (
              title: e.title,
              artist: (release['artist-credit'] as List?)
                  ?.map((e) => e['name'] as String?)
                  .where((e) => e != null)
                  .join(' / '),
              album: release['title'] as String?,
              coverUrl: Uri(
                scheme: 'https',
                host: 'coverartarchive.org',
                pathSegments: ['release', release['id'], 'front'],
              ),
            ),
          ),
        )
        .toList();
    return results;
  }

  Future<String?> _getImagePath(String? label) async {
    final imageType = XTypeGroup(
      label: label,
      extensions: <String>['jpg', 'jpeg', 'png', 'gif', 'webp'],
      mimeTypes: <String>['image/*'], // 某些平台支持通配符
    );
    final file = await openFile(acceptedTypeGroups: [imageType]);
    return file?.path;
  }
}

class _LyricEditDialog extends HookWidget {
  const _LyricEditDialog({required this.initValue, this.title});
  final String initValue;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController(text: initValue);
    useEffect(() {
      textController.selection = const TextSelection.collapsed(offset: 0);
      return null;
    }, []);

    final textValue = useListenable(textController);

    final canCopy = !textController.selection.isCollapsed;
    final canPaste = useState(false);
    final lifecycleState = useAppLifecycleState();
    useEffect(() {
      _checkClipboard().then(canPaste.set);
      return null;
    }, [textValue.text, lifecycleState]);

    final undoController = useMemoized(() => UndoHistoryController());
    useEffect(() => undoController.dispose, [undoController]);
    final historyValue = useValueListenable(undoController);

    final appBar = AppBar(
      leading: const CloseButton(),
      title: (title ?? '').asText(),
      actions: [
        IconButton(
          onPressed: historyValue.canUndo ? undoController.undo : null,
          icon: Icon(Icons.undo),
        ),
        IconButton(
          onPressed: historyValue.canRedo ? undoController.redo : null,
          icon: Icon(Icons.redo),
        ),
        8.0.asWidth(),
        IconButton(
          onPressed: canCopy ? textController.copySelectionToClipboard : null,
          icon: Icon(Icons.copy),
        ),
        IconButton(
          onPressed: canPaste.value ? textController.pasteFromClipboard : null,
          icon: Icon(Icons.paste),
        ),
        8.0.asWidth(),
      ],
    );

    final content = Scaffold(
      appBar: appBar,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: TextField(
          controller: textController,
          undoController: undoController,
          maxLines: null,
          autofocus: true,
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Navigator.pop(context, textValue.text);
      },
      child: content,
    );
  }

  Future<bool> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text?.isNotEmpty ?? false;
  }
}
