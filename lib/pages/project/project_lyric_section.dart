import 'dart:io';

import 'package:concha/utils/utils.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

import 'actions.dart';
import 'providers.dart';
import '../../models/models.dart';
import '../../services/lrclib_service.dart';
import '../../services/lyric_translation_service.dart';
import '../../services/play_controller.dart';
import '../../widgets/popup_widget.dart';

class ProjectLyricSection extends StatefulWidget {
  const ProjectLyricSection({super.key});

  @override
  State<ProjectLyricSection> createState() => _ProjectLyricSectionState();
}

class _ProjectLyricSectionState extends State<ProjectLyricSection> {
  late final _playController = context.read<PlayController>();
  late final _lyricController = context.read<LyricController>();
  late final _project = context.read<Project>();

  String? _lrc, _tlrc;

  String? _searchKeyword;

  @override
  void initState() {
    super.initState();

    _playController.positionNotifier.addListener(_updateLyricPosition);
    _lyricController.setOnTapLineCallback((position) {
      _playController.seekTo(position);
      _playController.startPositionNotifier.value = position;
      _lyricController.stopSelection();
    });
    _loadLyric();
  }

  @override
  void dispose() {
    _playController.positionNotifier.removeListener(_updateLyricPosition);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _lrc == null ? _buildEmptyContent() : _buildContent();
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
    return [
      _buildLyricView(),
      _buildLyricToolbar().positioned(top: 12.0, left: 12.0),
      if (_searchKeyword != null)
        _SearchPanel(
          initKeyword: _searchKeyword!,
          onLyricSelected: (value) {
            _lyricController.loadLyric(value);
          },
          onConfirm: (lrc) async {
            if (lrc != null) {
              await File(_project.path.lyric).writeAsString(lrc);
            }
            setState(() {
              _lrc = lrc;
              _searchKeyword = null;
            });
          },
        ).positioned(top: 16.0, bottom: 16.0, right: 16.0, width: 300.0),
    ].toStack();
  }

  Widget _buildLyricView() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return LyricView(
      controller: _lyricController,
      style: LyricStyles.default1.copyWith(
        textStyle: textTheme.displaySmall!.copyWith(
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
    final notSearchMode = _searchKeyword == null;
    return [
      if (notSearchMode)
        _LoadingButton(
          icon: Icon(Icons.translate),
          tooltip: '翻译歌词',
          onPressed: _createTranslate,
        ),
      _OffsetButton(),
      if (notSearchMode)
        ValueListenableBuilder(
          valueListenable: context.read<ReadAloudPendingNotifier>(),
          builder: (context, isPending, child) => _BusyButton(
            icon: Icon(Icons.record_voice_over),
            isBusy: isPending,
            tooltip: '朗读当前歌词',
            onPressed: Actions.handler(context, ReadAloudCurrentLyricIntent()),
          ),
        ),
      if (notSearchMode)
        IconButton.filledTonal(
          onPressed: () {
            setState(() {
              _lrc = null;
              _tlrc = null;
            });
          },
          tooltip: '清除歌词',
          icon: Icon(Icons.subtitles_off),
        ),
    ].toColumn(mainAxisSize: .min, separator: const SizedBox(height: 16.0));
  }

  void _updateLyricPosition() {
    _lyricController.setProgress(_playController.positionNotifier.value);
  }

  Future<void> _createTranslate() async {
    _tlrc = await LyricTranslationService().translate(_lrc!);

    await File(_project.path.lyricT).writeAsString(_tlrc!);

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
    await File(_project.path.lyric).writeAsString(_lrc!);

    setState(() {
      _updateLyric();
    });
  }

  void _searchLyric() {
    setState(() {
      _lrc = '';
      final m = _project.metadata;
      _searchKeyword = '${m.title} ${m.artist ?? ""}'.trim();
    });
  }

  Future<void> _loadLyric() async {
    final lrcFile = File(_project.path.lyric);
    if (await lrcFile.exists()) {
      _lrc = await lrcFile.readAsString();
    }

    final tlrcFile = File(_project.path.lyricT);
    if (await tlrcFile.exists()) {
      _tlrc = await tlrcFile.readAsString();
    }

    _lyricController.lyricOffset = _project.lyricOffset.inMilliseconds;

    _updateLyric();
    _updateLyricPosition();
    setState(() {});
  }

  void _updateLyric() {
    if (_lrc == null) return;
    _lyricController.loadLyric(_lrc!, translationLyric: _tlrc);
  }
}

class _LoadingButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget icon;
  final String? tooltip;

  const _LoadingButton({this.onPressed, required this.icon, this.tooltip});

  @override
  State<_LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<_LoadingButton> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    return _BusyButton(
      isBusy: _isBusy,
      icon: widget.icon,
      tooltip: widget.tooltip,
      onPressed: () async {
        setState(() {
          _isBusy = true;
        });
        try {
          await widget.onPressed?.call();
        } catch (e) {
          if (context.mounted) {
            context.showSnackBarText('失败：$e');
          }
        } finally {
          setState(() {
            _isBusy = false;
          });
        }
      },
    );
  }
}

class _BusyButton extends StatelessWidget {
  final bool isBusy;
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;

  const _BusyButton({
    required this.isBusy,
    this.onPressed,
    required this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: isBusy ? null : onPressed,
      tooltip: tooltip,
      icon: isBusy
          ? const SizedBox.square(
              dimension: 16.0,
              child: CircularProgressIndicator(strokeWidth: 2.0),
            )
          : icon,
    );
  }
}

class _OffsetButton extends StatefulWidget {
  const _OffsetButton();

  @override
  State<_OffsetButton> createState() => _OffsetButtonState();
}

class _OffsetButtonState extends State<_OffsetButton> {
  late final _controller = context.read<LyricController>();
  late final _project = context.read<Project>();

  bool _isOpen = false;

  final _offsetNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _offsetNotifier.addListener(
      () => _controller.lyricOffset = _offsetNotifier.value,
    );
    _offsetNotifier.value = _project.lyricOffset.inMilliseconds;
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
                  onChangeEnd: (value) => _project.lyricOffset = Duration(
                    milliseconds: value.round(),
                  ),
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
          tooltip: '调整歌词延迟',
          icon: Icon(Icons.timer),
        ),
      ),
    );
  }

  void _setVisible(bool visible) {
    setState(() {
      _isOpen = visible;
    });
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

  int? _selected;

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
    final colors = Theme.of(context).colorScheme;
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
            child: RadioGroup(
              groupValue: _selected,
              onChanged: (value) {
                setState(() {
                  _selected = value;
                });

                if (value != null) {
                  final lyric = _data[value].syncedLyrics;
                  widget.onLyricSelected(lyric);
                }
              },
              child: ListView(
                children: _data.indexed
                    .map(
                      (e) => RadioListTile(
                        value: e.$1,
                        title: Text(
                          '[${e.$1}] ${e.$2.trackName} - ${e.$2.artistName}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ).expanded(),
          Material(
            color: Colors.transparent,
            child: ListTile(
              onTap: () => widget.onConfirm(
                _selected == null ? null : _data[_selected!].syncedLyrics,
              ),
              title: Text(
                _selected == null ? '取消' : '确定',
              ).textColor(colors.primary).center(),
            ),
          ),
        ]
        .toColumn()
        .backgroundColor(colors.surfaceContainerHigh.withAlpha(220))
        .clipRRect(all: 30.0);
  }

  Future<void> _search() async {
    setState(() {
      _isBusy = true;
    });

    try {
      _data = await LrcLibService().search(_textController.text);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
}
