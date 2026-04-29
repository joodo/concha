import 'dart:io';

import 'package:animations/animations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:styled_widget/styled_widget.dart';

import '/adaptive_widgets/adaptive_widgets.dart';
import '/generated/l10n.dart';
import '/icon_font/icon_font.dart';
import '/llm/llm.dart';
import '/lrclib/lrclib.dart';
import '/lyric/lyric.dart' hide LyricController;
import '/mvsep/mvsep.dart';
import '/preferences/preferences.dart';
import '/projects/projects.dart';
import '/shortcuts/shortcuts.dart';
import '/utils/utils.dart';

import '../widgets/animated_linear_indicator.dart';
import '../widgets/popup_widget.dart';

import 'actions.dart';
import 'riverpod.dart';

class ProjectLyricSection extends HookConsumerWidget {
  const ProjectLyricSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearchingNotifier = useValueNotifier<bool>(false);

    final controller = ref.watch(lyricControllerProvider(ref.projectId!)).value;
    if (controller == null) return const SizedBox.shrink();

    final hasLyric = ref.watch(
      lyricProvider(
        ref.projectId!,
        isTranslate: false,
      ).select((asyncValue) => asyncValue.value != null),
    );
    return ValueListenableBuilder(
      valueListenable: isSearchingNotifier,
      builder: (context, isSearching, child) {
        return hasLyric || isSearching
            ? _Content(isSearchingNotifier: isSearchingNotifier)
            : _EmptyContent(
                onLocalPathSelected: (lyricPath) async {
                  final lrc = await File(lyricPath).readAsString();
                  _setProjectLyricAndGenerateSummary(ref, lrc);
                },
                onSearch: () => isSearchingNotifier.value = true,
              );
      },
    );
  }
}

class _Content extends HookConsumerWidget {
  const _Content({required this.isSearchingNotifier});
  final ValueNotifier<bool> isSearchingNotifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyricController = ref.lyricController!;

    final wordByWordNotifier = useValueNotifier<String?>(null);
    ref.listen(
      lyricProvider(ref.projectId!, isTranslate: false),
      (previous, next) => wordByWordNotifier.clear(),
    );

    return [
      ValueListenableBuilder(
        valueListenable: isSearchingNotifier,
        builder: (context, isSearching, child) => Consumer(
          builder: (context, ref, child) => _LyricView(
            controller: lyricController,
            onWordForWord: wordByWordNotifier.set,
            isPreview: isSearching,
          ),
        ),
      ),
      ValueListenableBuilder(
        valueListenable: isSearchingNotifier,
        builder: (context, isSearching, child) =>
            _LyricToolbar(isPreview: isSearching),
      ).positioned(top: 12.0, left: 12.0),
      ValueListenableBuilder(
        valueListenable: wordByWordNotifier,
        builder: (context, sentense, child) {
          if (sentense == null) return const SizedBox.shrink();
          return _WordForWordPanel(
            sentense: sentense.trim(),
            onClose: wordByWordNotifier.clear,
          ).positioned(top: 16.0, bottom: 16.0, right: 16.0, width: 300.0);
        },
      ),
      ValueListenableBuilder(
        valueListenable: isSearchingNotifier,
        builder: (context, isSearching, child) {
          if (!isSearching) return const SizedBox.shrink();
          return _SearchPanel(
            metadata: ref.project!.metadata,
            onLyricSelected: ref.lyricNotifier(isTranslate: false)!.preview,
            onConfirm: (lrc) async {
              if (lrc != null) {
                _setProjectLyricAndGenerateSummary(ref, lrc);
              }
              isSearchingNotifier.value = false;
            },
          ).positioned(top: 16.0, bottom: 16.0, right: 16.0, width: 300.0);
        },
      ),
    ].toStack();
  }
}

class _LyricView extends ConsumerWidget {
  const _LyricView({
    required this.controller,
    required this.onWordForWord,
    required this.isPreview,
  });

  final LyricController controller;
  final bool isPreview;
  final ValueSetter<String> onWordForWord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyricView = LyricView(
      // Avoid text layout not available on textStyle with shadow when ColorScheme changed
      key: ValueKey(context.colors),
      controller: controller,
      style: LyricStyles.default1.copyWith(
        textStyle: context.textStyles.displaySmall?.copyWith(
          color: context.colors.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        activeStyle: context.textStyles.displayMedium?.copyWith(
          shadows: [
            Shadow(
              blurRadius: 10,
              color: context.colors.primaryContainer.withValues(alpha: 0.6),
            ),
          ],
        ),
        translationStyle: context.textStyles.titleMedium?.copyWith(
          color: context.colors.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        activeHighlightColor: context.colors.primary,
        translationActiveColor: context.colors.primary.withValues(alpha: 0.8),
        selectedColor: context.colors.tertiary,
        selectedTranslationColor: context.colors.tertiary.withValues(
          alpha: 0.8,
        ),
      ),
      width: double.infinity,
      height: double.infinity,
    );

    final menuAnchor = MenuAnchor(
      consumeOutsideTap: true,
      builder: (context, menuController, child) {
        return GestureDetector(
          onSecondaryTapDown: (detail) {
            menuController.isOpen
                ? menuController.close()
                : menuController.open(position: detail.localPosition);
          },
          child: child,
        );
      },
      menuChildren: [
        if (!isPreview)
          MenuItemButton(
            onPressed: controller.currentText == null
                ? null
                : () => onWordForWord(controller.currentText!),
            leadingIcon: Icon(Icons.search),
            child: S.of(context).wordByWordExplanation.asText(),
          ),
        if (!isPreview) const Divider(),

        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: controller.currentText == null
                  ? null
                  : () async {
                      await controller.currentText!.copyToClipboard();
                      if (context.mounted) {
                        context.showSnackBarText(
                          S.of(context).currentLyricCopyed,
                        );
                      }
                    },
              child: S.of(context).copyCurrentLyric.asText(),
            ),
            MenuItemButton(
              onPressed: () async {
                await controller.lyricText!.copyToClipboard();
                if (context.mounted) {
                  context.showSnackBarText(S.of(context).wholeLyricCopyed);
                }
              },
              child: S.of(context).copyWholeLyric.asText(),
            ),
          ],
          leadingIcon: Icon(Icons.copy),
          child: S.of(context).copy.asText(),
        ),
        const Divider(),

        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: () => _editLyric(ref, isTranslate: false),
              child: S.of(context).editLyric.asText(),
            ),
            MenuItemButton(
              onPressed: () => _editLyric(ref, isTranslate: true),
              child: S.of(context).editTranslateLyric.asText(),
            ),
          ],
          leadingIcon: const Icon(Icons.edit),
          child: S.of(context).edit.asText(),
        ),
        MenuItemButton(
          onPressed: ref.lyricNotifier(isTranslate: false)!.clearTemporarily,
          leadingIcon: const Icon(Icons.subtitles_off),
          child: S.of(context).clearLyric.asText(),
        ),
      ],
    );

    return [lyricView, menuAnchor].toStack(fit: .expand);
  }

  Future<void> _editLyric(WidgetRef ref, {required bool isTranslate}) async {
    Navigator.of(ref.context).pushNamed(
      '/lyric',
      arguments: {'id': ref.projectId, 'isTranslate': isTranslate},
    );
  }
}

class _LyricToolbar extends ConsumerWidget {
  const _LyricToolbar({required this.isPreview});

  final bool isPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyricController = ref.lyricController!;

    return [
      if (!isPreview)
        _LoadingButton(
          icon: Icon(Icons.translate),
          onPressed: () async {
            final lrc = await File(ref.project!.path.lyric).readAsString();

            if (!context.mounted) return;
            final targetLangs = await showModal<List<String>?>(
              context: context,
              builder: (context) => _LyricTranslateDialog(),
            );
            if (targetLangs == null) return;

            final tlrc = await createLrcTranslation(
              lrc,
              ref.read(lyricTranslateLangsProvider),
            );

            await ref.lyricNotifier(isTranslate: true)!.save(tlrc);
          },
        ).tooltip(S.of(context).translateLyric),
      _OffsetButton(onChanged: (value) => lyricController.lyricOffset = value),
      if (!isPreview)
        Consumer(
          builder: (context, ref, child) {
            final readAloudState = ref.watch(readAloud);
            return _BusyButton(
              icon: Icon(Icons.record_voice_over),
              isBusy: readAloudState.isPending,
              onPressed: Actions.handler(
                context,
                ReadAloudIntent.currentLyric(),
              ),
            ).tooltipWithShortcuts(
              S.of(context).readAloudCurrentLyric,
              shortcuts: [.readLyric],
            );
          },
        ),
    ].toColumn(mainAxisSize: .min, separator: const SizedBox(height: 16.0));
  }
}

class _SearchPanel extends HookConsumerWidget {
  static final _mockData = List.filled(
    7,
    LrcLibLyric(
      trackName: MockData.words(4),
      artistName: MockData.words(4),
      albumName: MockData.words(4),
      duration: Duration.zero,
      plainLyrics: '',
      syncedLyrics: '',
    ),
  );

  const _SearchPanel({
    required this.onLyricSelected,
    required this.onConfirm,
    required this.metadata,
  });

  final Metadata metadata;
  final ValueSetter<String> onLyricSelected;
  final ValueSetter<String?> onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initKeyword = [
      metadata.title,
      metadata.album,
      metadata.artist,
    ].map((s) => s?.trim()).where((s) => s != null && s.isNotEmpty).join(' ');
    final textController = useTextEditingController(text: initKeyword);

    final searchTask = useState<Future<List<LrcLibLyric>>?>(null);
    void doSearch() {
      searchTask.value = LrcLibService.i.search(textController.text);
    }

    useInitiate(doSearch);

    final selected = useState<int?>(null);

    final snapshot = useFuture(searchTask.value);
    final isLoading = snapshot.connectionState == .waiting;

    final searchField = SearchBar(
      controller: textController,
      onSubmitted: (value) => doSearch(),
      trailing: [
        isLoading
            ? const SizedBox.square(
                dimension: 16.0,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ).padding(right: 12.0)
            : IconButton(onPressed: doSearch, icon: Icon(Icons.search)),
      ],
    );
    final searchBar = IgnoreConchaShortcuts(child: searchField);

    final data = snapshot.data ?? _mockData;
    final listView = ListView(
      padding: EdgeInsets.only(top: 8.0),
      children: data.indexed.map((e) {
        final subtitleText = [e.$2.albumName, e.$2.artistName]
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .join(' - ')
            .nullIfEmpty;
        return RadioListTile(
          value: e.$1,
          title: '[${e.$1}] ${e.$2.trackName}'.asText(),
          subtitle: subtitleText?.asText(),
        );
      }).toList(),
    );
    final body = data.isEmpty
        ? S
              .of(context)
              .noMatchingLyricsFound
              .asText()
              .textColor(context.colors.onSurfaceVariant)
              .center()
        : Material(
            color: Colors.transparent,
            child: RadioGroup(
              groupValue: selected.value,
              onChanged: (value) {
                selected.value = value;

                if (value != null) {
                  final lyric = data[value].syncedLyrics;
                  onLyricSelected(lyric);
                }
              },
              child: MediaQuery.removePadding(
                // For parent Scaffold use extendBodyBehindAppBar: true
                context: context,
                removeTop: true,
                child: Skeletonizer(enabled: isLoading, child: listView),
              ),
            ),
          );

    final action = Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () =>
            onConfirm(selected.value.mapOrNull((v) => data[v].syncedLyrics)),
        title: Text(
          selected.value == null ? S.of(context).cancel : S.of(context).confirm,
        ).textColor(context.colors.primary).center(),
      ),
    );

    return [searchBar, body.expanded(), action]
        .toColumn()
        .backgroundColor(context.colors.surfaceContainerHigh.withAlpha(220))
        .clipRRect(all: 30.0);
  }
}

class _WordForWordPanel extends ConsumerWidget {
  static final _mockData = TranslationResult(
    sourceLang: MockData.words(2),
    sentence: MockData.sentence(),
    translate: MockData.sentence(),
    detail: List.generate(
      5,
      (index) => TranslationDetail(
        word: MockData.word,
        translate: MockData.words(2),
        explanation: MockData.sentence(minWordsCount: 10),
      ),
    ),
  );

  const _WordForWordPanel({required this.sentense, required this.onClose});

  final String sentense;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(wordForWordProvider(sentense));

    final header = [
      Consumer(
        builder: (context, ref, child) {
          final readAloudState = ref.watch(readAloud);
          return IconButton.outlined(
            icon: Icon(Icons.record_voice_over),
            tooltip: S.of(context).readAloudLyric,
            onPressed: readAloudState.isPending
                ? null
                : Actions.handler(context, ReadAloudIntent(sentense)),
          );
        },
      ),
      IconButton.outlined(
        icon: Icon(Icons.refresh),
        tooltip: S.of(context).regenerateExplanation,
        onPressed: !dataAsync.isRefreshing && !dataAsync.isLoading
            ? () => ref.invalidate(wordForWordProvider(sentense))
            : null,
      ),
      const Spacer(),
      CloseButton(onPressed: onClose),
    ].toRow(separator: 8.0.asWidth());

    final content = [
      header.padding(horizontal: 16.0, vertical: 12.0),
      AnimatedLinearIndicator(isRunning: dataAsync.isRefreshing),
      switch (dataAsync) {
        AsyncError(:final error) => SelectableText(error.toString()).center(),
        _ => Skeletonizer(
          enabled: !dataAsync.hasValue,
          child: _buildContent(ref, dataAsync.value ?? _mockData),
        ),
      }.padding(horizontal: 16.0, bottom: 12.0, top: 4.0).expanded(),
    ].toColumn(crossAxisAlignment: .stretch);

    return content.backgroundColor(context.colors.surface).clipRRect(all: 30.0);
  }

  Widget _buildContent(WidgetRef ref, TranslationResult data) {
    final words =
        ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: 12.0),
              itemCount: data.detail.length,
              itemBuilder: (context, index) {
                final detail = data.detail[index];
                return [
                      [
                        detail.word
                            .asText()
                            .fontWeight(.bold)
                            .textColor(context.colors.primary),
                        detail.translate.asText().textColor(
                          context.colors.onSurface,
                        ),
                      ].toWrap(spacing: 12.0),
                      if (detail.explanation?.isNotEmpty == true)
                        detail.explanation!
                            .asText()
                            .textStyle(context.textStyles.bodySmall!)
                            .textColor(context.colors.onSurfaceVariant),
                    ]
                    .toColumn(
                      crossAxisAlignment: .start,
                      separator: 8.0.asHeight(),
                    )
                    .padding(horizontal: 12);
              },
              separatorBuilder: (context, index) => Divider(),
            )
            .backgroundColor(ref.context.colors.surfaceContainerLow)
            .clipRRect(all: 12.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < 300) return words;

        return [
          _buildSentenceBlock(
            context,
            data.sourceLang,
            sentense,
            context.colors.surfaceContainerLow,
          ),
          _buildSentenceBlock(
            context,
            ref.read(translateLangProvider),
            data.translate,
            context.colors.primaryContainer,
          ),
          [
                S
                    .of(context)
                    .wordByWordExplanation
                    .asText()
                    .textStyle(context.textStyles.titleMedium!),
                words.flexible(),
              ]
              .toColumn(crossAxisAlignment: .start, separator: 8.0.asHeight())
              .expanded(),
        ].toColumn(crossAxisAlignment: .stretch, separator: 16.0.asHeight());
      },
    );
  }

  Widget _buildSentenceBlock(
    BuildContext context,
    String title,
    String content,
    Color color,
  ) {
    return [
          title
              .asText()
              .textStyle(context.textStyles.labelSmall!)
              .textColor(context.colors.onSurfaceVariant),
          content.asText(),
        ]
        .toColumn(crossAxisAlignment: .start, separator: 4.0.asHeight())
        .padding(horizontal: 16.0, vertical: 12.0)
        .backgroundColor(color)
        .clipRRect(all: 12.0);
  }
}

class _LyricTranslateDialog extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langs = useState<List<String>>(ref.read(lyricTranslateLangsProvider));
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final addLang = useCallback(() {
      if (controller.text.isEmpty) return;
      langs.value = List.from(langs.value)..add(controller.text);
      controller.clear();
      focusNode.requestFocus();
    });

    final tagField = TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        prefixIcon: langs.value.isNotEmpty
            ? langs.value.indexed
                  .map(
                    (e) => InputChip(
                      label: e.$2.asText(),
                      onDeleted: () {
                        langs.value = List.from(langs.value)..removeAt(e.$1);
                      },
                    ),
                  )
                  .toList()
                  .toWrap(spacing: 4.0)
                  .constrained(maxWidth: 400.0)
            : null,
        hintText: S.of(context).addLanguage,
        helperText: S.of(context).addLanguageHint,
      ),
      onSubmitted: (_) => addLang(),
    );

    return AlertDialog(
      icon: const Icon(Icons.translate),
      content: tagField.constrained(width: 500),
      actions: [
        ListenableBuilder(
          listenable: controller,
          builder: (context, child) => FilledButton(
            onPressed: langs.value.isNotEmpty && controller.text.isEmpty
                ? () {
                    ref
                        .read(lyricTranslateLangsProvider.notifier)
                        .set(langs.value);
                    Navigator.of(context).pop(langs.value);
                  }
                : null,
            child: S.of(context).translate.asText(),
          ),
        ),
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: S.of(context).cancel.asText(),
        ),
      ],
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({
    required this.onLocalPathSelected,
    required this.onSearch,
  });

  final ValueSetter<String> onLocalPathSelected;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return HookConsumer(
      builder: (context, ref, child) {
        final progress = useState<double?>(null);
        final isPending = useState<bool>(false);

        return AdaptiveLayoutBuilder(
          builder: (context, layoutSize) {
            final isLarge = layoutSize.breakPoint > .compact;

            final buttons = [
              _buildButton(
                context,
                isLarge: isLarge,
                title: S.of(context).openLocal,
                icon: Icons.folder_open,
                onTap: () => _openLocalLyric(context),
              ),
              _buildButton(
                context,
                isLarge: isLarge,
                title: S.of(context).searchOnline,
                icon: Icons.search,
                onTap: onSearch,
              ),
              _buildButton(
                context,
                isLarge: isLarge,
                title: isPending.value
                    ? S.of(context).transcribing
                    : S.of(context).aiTranscribe,
                icon: isPending.value ? null : UiIcons.sparkles,
                progress: progress.value,
                onTap: !isPending.value
                    ? () async {
                        final vocalIsolated = ref
                            .read(separationPathProvider(ref.projectId!))
                            .hasValue;
                        if (!vocalIsolated) {
                          context.showSnackBarText(
                            S.of(context).vocalIsolationIsRequired,
                          );
                          return;
                        }

                        isPending.value = true;

                        final provider = transcribedLyricProvider(
                          ref.projectId!,
                        );
                        final subcription = ref.listenManual(provider, (
                          previous,
                          next,
                        ) {
                          if (next is AsyncLoading) {
                            progress.value = next.progress as double?;
                          }
                        });

                        try {
                          final lrc = await ref.read(provider.future);
                          _setProjectLyricAndGenerateSummary(ref, lrc);
                        } finally {
                          subcription.close();
                          if (context.mounted) isPending.value = false;
                        }
                      }
                    : null,
              ),
            ];

            final content = isLarge
                ? buttons.toRow(mainAxisSize: .min, separator: 32.0.asWidth())
                : buttons.toColumn(
                    mainAxisSize: .min,
                    separator: 12.0.asHeight(),
                  );
            return content.center();
          },
        );
      },
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required bool isLarge,
    required String title,
    IconData? icon,
    double? progress,
    VoidCallback? onTap,
  }) {
    final iconWidget = icon != null
        ? Icon(icon)
        : Builder(
            builder: (context) {
              final size = IconTheme.of(context).size!;
              return CircularProgressIndicator(
                value: progress,
              ).constrained(width: size, height: size);
            },
          );

    if (!isLarge) {
      return FilledButton.icon(
        onPressed: onTap,
        label: title.asText(),
        icon: ProgressIndicatorTheme(
          data: ProgressIndicatorThemeData(
            strokeWidth: 4.0,
            circularTrackPadding: EdgeInsets.all(4.0),
          ),
          child: iconWidget,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: context.colors.tertiaryContainer,
          foregroundColor: context.colors.onTertiaryContainer,
        ).large(context),
      );
    }

    final enabled = onTap != null;
    final card = Card(
      child: InkWell(
        onTap: onTap,
        child:
            [
                  iconWidget,
                  Text(
                    title,
                    style: context.textStyles.bodyLarge!.copyWith(
                      color: enabled
                          ? context.colors.onTertiaryContainer
                          : context.colors.onSurface.withAlpha(0.38.toUint8),
                    ),
                  ),
                ]
                .toColumn(mainAxisSize: .min, separator: 8.0.asHeight())
                .padding(all: 16.0),
      ),
    ).constrained(minWidth: 120.0);
    return Theme(
      data: context.theme.copyWith(
        iconTheme: IconThemeData(
          size: 48.0,
          color: enabled
              ? context.colors.onTertiaryContainer
              : context.colors.onSurface.withAlpha(0.38.toUint8),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          strokeWidth: 4.0,
          circularTrackPadding: EdgeInsets.all(8.0),
        ),
        cardTheme: CardThemeData(
          clipBehavior: .hardEdge,
          color: enabled
              ? context.colors.tertiaryContainer
              : context.colors.onSurface.withAlpha(0.1.toUint8),
        ),
      ),
      child: DefaultTextStyle(
        style: context.textStyles.bodyLarge!.copyWith(
          color: enabled
              ? context.colors.onTertiaryContainer
              : context.colors.onSurface.withAlpha(0.38.toUint8),
        ),
        child: card,
      ),
    );
  }

  Future<void> _openLocalLyric(BuildContext context) async {
    final lyricPath = await _getLyricPath(label: S.of(context).lyricFile);
    if (lyricPath == null) return;

    onLocalPathSelected(lyricPath);
  }

  Future<String?> _getLyricPath({String? label}) async {
    final audioTypeGroup = XTypeGroup(
      label: label,
      extensions: <String>['lrc'],
      mimeTypes: <String>['text/plain', 'application/octet-stream'],
    );

    final XFile? picked = await openFile(acceptedTypeGroups: [audioTypeGroup]);

    return picked?.path;
  }
}

class _LoadingButton extends HookWidget {
  final Future<void> Function()? onPressed;
  final Widget icon;

  const _LoadingButton({this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isBusyNotifier = useValueNotifier<bool>(false);

    return ValueListenableBuilder(
      valueListenable: isBusyNotifier,
      builder: (context, isBusy, child) {
        return _BusyButton(
          isBusy: isBusy,
          icon: icon,
          onPressed: () async {
            isBusyNotifier.value = true;
            try {
              await onPressed?.call();
            } catch (e) {
              if (context.mounted) {
                context.showSnackBarText('${S.of(context).failed}: $e');
              }
            } finally {
              isBusyNotifier.value = false;
            }
          },
        );
      },
    );
  }
}

class _BusyButton extends StatelessWidget {
  final bool isBusy;
  final VoidCallback? onPressed;
  final Widget icon;

  const _BusyButton({required this.isBusy, this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: isBusy ? null : onPressed,
      icon: isBusy
          ? const SizedBox.square(
              dimension: 16.0,
              child: CircularProgressIndicator(strokeWidth: 2.0),
            )
          : icon,
    );
  }
}

class _OffsetButton extends HookConsumerWidget {
  const _OffsetButton({required this.onChanged});

  final ValueSetter<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offsetNotifier = useValueNotifier<int>(
      ref.project!.lyricOffset.inMilliseconds,
    );
    final isOpen = useState<bool>(false);

    final link = LayerLink();
    return PopupWidget(
      showing: isOpen.value,
      popupBuilder: (context) => ValueListenableBuilder(
        valueListenable: offsetNotifier,
        builder: (context, offset, child) {
          return [
                Slider(
                  min: -10_000.0,
                  max: 10_000.0,
                  divisions: 200,
                  onChanged: (value) {
                    offsetNotifier.value = value.round();
                    onChanged(offsetNotifier.value);
                  },
                  onChangeEnd: (value) => ref.projectNotifier!.updateAndSave(
                    (old) =>
                        old.copyWith(lyricOffset: value.round().milliseconds),
                  ),
                  value: offsetNotifier.value.toDouble(),
                ),
                Text(
                  '${offset / 1000} s',
                ).constrained(width: 48.0).padding(right: 16.0),
              ]
              .toRow(mainAxisSize: .min)
              .backgroundColor(Theme.of(context).colorScheme.surfaceContainer)
              .clipRRect(all: 16.0);
        },
      ),
      layoutBuilder: (context, popup) => GestureDetector(
        behavior: .opaque,
        onTap: () => isOpen.value = false,
        child: UnconstrainedBox(
          child: CompositedTransformFollower(
            link: link,
            targetAnchor: .centerRight,
            followerAnchor: .centerLeft,
            offset: Offset(16.0, 0),
            child: popup,
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: link,
        child: IconButton.filledTonal(
          onPressed: () => isOpen.value = !isOpen.value,
          tooltip: S.of(context).adjustLyricOffset,
          icon: Icon(Icons.timer),
        ),
      ),
    );
  }
}

Future<void> _setProjectLyricAndGenerateSummary(
  WidgetRef ref,
  String lrc, {
  bool isTranslate = false,
}) async {
  await ref.lyricNotifier(isTranslate: isTranslate)!.save(lrc);
  await ref.projectNotifier!.generateSummaryIfAbsent();
}
