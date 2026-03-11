import 'dart:io';

import 'package:animations/animations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../models/models.dart';
import '../../services/lrclib_service.dart';
import '../../services/lyric_translation_service.dart';
import '../../utils/utils.dart';
import '../../play_controller.dart';
import '../../widgets/popup_widget.dart';

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

  final _toolbarVisibleNotifier = AutoResetNotifier(const Duration(seconds: 1));

  String? _searchKeyword;

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
    return [
          _buildBigButton(
            onTap: _openLocalLyric,
            title: '打开本地',
            icon: Icons.folder_open,
          ),
          _buildBigButton(
            onTap: _searchLyric,
            title: '在线搜索',
            icon: Icons.search,
          ),
        ]
        .toRow(mainAxisSize: .min, separator: const SizedBox(width: 32.0))
        .center();
  }

  Widget _buildBigButton({
    VoidCallback? onTap,
    required String title,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: .hardEdge,
      color: colorScheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child:
            [
                  Icon(icon, size: 48.0, color: colorScheme.secondary),
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                ]
                .toColumn(
                  mainAxisSize: .min,
                  separator: const SizedBox(height: 8.0),
                )
                .padding(all: 16.0),
      ),
    );
  }

  Widget _buildContent() {
    return MouseRegion(
      onEnter: (event) => _toolbarVisibleNotifier.lockUp('mouse in'),
      onExit: (event) => _toolbarVisibleNotifier.unlock('mouse in'),
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
        if (_searchKeyword != null)
          _SearchPanel(
            initKeyword: _searchKeyword!,
            onLyricSelected: (value) {
              _lyricController.loadLyric(value);
            },
            onConfirm: (lrc) async {
              if (lrc != null) {
                await File(widget.project.lyricPath).writeAsString(lrc);
              }
              setState(() {
                _lrc = lrc;
                _searchKeyword = null;
              });
            },
          ).positioned(top: 16.0, bottom: 16.0, right: 16.0, width: 300.0),
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
      _OffsetButton(
        controller: _lyricController,
        onShow: () => _toolbarVisibleNotifier.lockUp('show offset'),
        onHide: () => _toolbarVisibleNotifier.unlock('show offset'),
      ),
      if (_searchKeyword == null)
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

  void _searchLyric() {
    setState(() {
      _lrc = '';
      final m = widget.project.metadata;
      _searchKeyword = '${m.title} ${m.artist ?? ""}'.trim();
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

class _OffsetButton extends StatefulWidget {
  final LyricController controller;
  final VoidCallback? onShow, onHide;
  final ValueSetter<int>? onChanged;

  const _OffsetButton({
    required this.controller,
    this.onShow,
    this.onHide,
    this.onChanged,
  });

  @override
  State<_OffsetButton> createState() => _OffsetButtonState();
}

class _OffsetButtonState extends State<_OffsetButton> {
  bool _isOpen = false;

  final _offsetNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _offsetNotifier.value = widget.controller.lyricOffset;
    _offsetNotifier.addListener(
      () => widget.controller.lyricOffset = _offsetNotifier.value,
    );
  }

  @override
  void dispose() {
    _offsetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final link = LayerLink();
    return PopupWidget(
      showing: _isOpen,
      popupBuilder: (context) => ValueListenableBuilder(
        valueListenable: _offsetNotifier,
        builder: (context, offset, child) {
          return [
                Slider(
                  min: -10_000.0,
                  max: 10_000.0,
                  divisions: 200,
                  onChanged: (value) {
                    _offsetNotifier.value = value.round();
                  },
                  onChangeEnd: (value) => widget.onChanged?.call(value.round()),
                  value: _offsetNotifier.value.toDouble(),
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
        onTap: () => _setVisible(false),
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
          onPressed: () => _setVisible(true),
          icon: Icon(Icons.timer),
        ),
      ),
    );
  }

  void _setVisible(bool visible) {
    setState(() {
      _isOpen = visible;
    });
    _isOpen ? widget.onShow?.call() : widget.onHide?.call();
  }
}

class _SearchPanel extends StatefulWidget {
  final String initKeyword;
  final ValueSetter<String> onLyricSelected;
  final ValueSetter<String?> onConfirm;

  const _SearchPanel({
    required this.initKeyword,
    required this.onLyricSelected,
    required this.onConfirm,
  });

  @override
  State<_SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<_SearchPanel> {
  final _textController = TextEditingController();
  bool _isBusy = false;
  List<LrcLibLyric> _data = [];

  String? _selected;

  @override
  void initState() {
    super.initState();

    _textController.text = widget.initKeyword;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _search();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return [
          SearchBar(
            controller: _textController,
            onSubmitted: (value) => _search(),
            trailing: [
              _isBusy
                  ? const SizedBox.square(
                      dimension: 16.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ).padding(right: 12.0)
                  : IconButton(onPressed: _search, icon: Icon(Icons.search)),
            ],
          ),
          Material(
            color: Colors.transparent,
            child: ListView(
              children: _data
                  .map(
                    (e) => ListTile(
                      title: Text('${e.trackName} - ${e.artistName}'),
                      onTap: () {
                        setState(() {
                          _selected = e.syncedLyrics;
                        });
                        widget.onLyricSelected(e.syncedLyrics);
                      },
                    ),
                  )
                  .toList(),
            ),
          ).expanded(),
          TextButton(
            onPressed: () => widget.onConfirm(_selected),
            child: Text(_selected == null ? '取消' : '确定'),
          ).padding(vertical: 12.0),
        ]
        .toColumn()
        .backgroundColor(
          Theme.of(context).colorScheme.surfaceContainerHigh.withAlpha(220),
        )
        .clipRRect(all: 30.0);
  }

  Future<void> _search() async {
    setState(() {
      _isBusy = true;
    });

    try {
      _data = await LrcLibService().search(_textController.text);
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }
}
