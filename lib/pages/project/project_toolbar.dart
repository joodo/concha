import 'package:concha/pages/project/providers.dart';
import 'package:concha/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/core/lyric_controller.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../services/mvsep_separation_service.dart';
import '../../services/play_controller.dart';
import '../../widgets/popup_widget.dart';
import 'actions.dart';
import 'expansible_button.dart';

class ProjectToolbar extends StatelessWidget {
  const ProjectToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final playController = context.read<PlayController>();
    final loopNotifier = context.read<LoopNotifier>();
    final attachNotifier = context.read<AttachToLyricNotifier>();
    final lyricController = context.read<LyricController>();
    return [
          ListenableBuilder(
            listenable: Listenable.merge([
              playController.isPlayNotifier,
              loopNotifier,
            ]),
            builder: (context, child) => IconButton.filled(
              onPressed: Actions.handler(context, const TogglePlayIntent()),
              icon: Icon(
                playController.isPlayNotifier.value
                    ? Icons.pause_rounded
                    : loopNotifier.value
                    ? Icons.slow_motion_video
                    : Icons.play_arrow,
                size: 32,
              ),
              tooltip: playController.isPlayNotifier.value
                  ? '暂停'
                  : loopNotifier.value
                  ? '从起点播放'
                  : '播放',
            ),
          ),
          ValueListenableBuilder(
            valueListenable: loopNotifier,
            builder: (context, value, child) => IconButton.outlined(
              onPressed: () => loopNotifier.value = !value,
              isSelected: value,
              tooltip: '从起点播放',
              icon: const Icon(Icons.repeat),
            ),
          ),
          ListenableBuilder(
            listenable: Listenable.merge([
              attachNotifier,
              lyricController.lyricNotifier,
            ]),
            builder: (context, child) => IconButton.outlined(
              onPressed: lyricController.lyricNotifier.value == null
                  ? null
                  : () => attachNotifier.value = !attachNotifier.value,
              tooltip: '位置吸附到歌词',
              isSelected: attachNotifier.value,
              icon: const Icon(Icons.my_location),
            ),
          ),
          IconButton(
            onPressed: playController.stop,
            tooltip: '停止',
            icon: const Icon(Icons.stop_rounded),
          ),
          const SizedBox(width: 8.0),
          LayoutBuilder(
            builder: (context, constraints) {
              final isExpanded = constraints.maxWidth >= 750.0;
              return [
                ValueListenableBuilder(
                  valueListenable: playController.volumeNotifier,
                  builder: (context, volumn, child) => ExpansibleButton(
                    isExpanded: isExpanded,
                    icon: Icon(
                      Icons.volume_up,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    value: volumn,
                    labelStringBuilder: (value) => '${(value * 100).round()} %',
                    divisions: 100,
                    onChanged: playController.setVolume,
                  ),
                ).tooltip('音量'),
                ValueListenableBuilder(
                  valueListenable: playController.speedNotifier,
                  builder: (context, speed, child) => ExpansibleButton(
                    isExpanded: isExpanded,
                    icon: Image.asset(
                      'assets/icons/metronome.png',
                      width: 24.0,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    value: speed,
                    min: 0.25,
                    max: 2.0,
                    labelStringBuilder: (value) => 'x $value',
                    divisions: 7,
                    onChanged: playController.setSpeed,
                  ),
                ).tooltip('速度'),
                ValueListenableBuilder(
                  valueListenable: playController.pitchNotifier,
                  builder: (context, pitch, child) => ExpansibleButton(
                    isExpanded: isExpanded,
                    icon: Image.asset(
                      'assets/icons/diapason.png',
                      width: 24.0,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    value: pitch.toDouble(),
                    min: -7,
                    max: 7,
                    labelStringBuilder: (value) {
                      final pitch = value.round();
                      final mark = switch (pitch) {
                        0 => '♮',
                        < 0 => '♭',
                        > 0 => '♯',
                        _ => '?',
                      };
                      return '[$pitch] $mark';
                    },
                    divisions: 14,
                    onChanged: (value) =>
                        playController.setPitch(value.round()),
                  ).tooltip('音调'),
                ),
                _MixTableButton(playController: playController),
              ].toRow(separator: const SizedBox(width: 12));
            },
          ).flexible(),
          _createDurationLabel(playController: playController),
        ]
        .toRow(separator: const SizedBox(width: 8.0))
        .padding(horizontal: 12.0, bottom: 12.0);
  }

  Widget _createDurationLabel({required PlayController playController}) {
    String formatDuration(Duration duration) {
      final minutes = duration.inMinutes
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      final seconds = duration.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      final hours = duration.inHours;

      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
      }

      return '$minutes:$seconds';
    }

    return ListenableBuilder(
      listenable: playController.positionNotifier,
      builder: (context, child) => Text(
        '${formatDuration(playController.positionNotifier.value)} / ${formatDuration(playController.duration)}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _MixTableButton extends StatefulWidget {
  const _MixTableButton({required this.playController});

  final PlayController playController;

  @override
  State<_MixTableButton> createState() => _MixTableButtonState();
}

class _MixTableButtonState extends State<_MixTableButton> {
  bool _isShowing = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final link = LayerLink();
    return PopupWidget(
      showing: _isShowing,
      popupBuilder: (context) => Material(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12.0),
        child: Consumer<Stream<MvsepTaskEvent>?>(
          builder: _popupContentBuilder,
        ).constrained(width: 240.0, height: 160.0),
      ),
      layoutBuilder: (context, popup) => GestureDetector(
        behavior: .opaque,
        onTap: () => setState(() {
          _isShowing = false;
        }),
        child: UnconstrainedBox(
          child: CompositedTransformFollower(
            link: link,
            targetAnchor: .topCenter,
            followerAnchor: .bottomCenter,
            offset: Offset(0, -16.0),
            child: popup,
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: link,
        child: ValueListenableBuilder(
          valueListenable: widget.playController.separateModeNotifier,
          builder: (context, isSep, child) {
            return IconButton.outlined(
              onPressed: () => setState(() {
                _isShowing = true;
              }),
              isSelected: isSep,
              icon: Image.asset(
                'assets/icons/mixing-table.png',
                width: 20.0,
                color: colors.onSurfaceVariant,
              ),
              selectedIcon: Image.asset(
                'assets/icons/mixing-table-fill.png',
                width: 20.0,
                color: colors.onInverseSurface,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _popupContentBuilder(
    BuildContext context,
    Stream<MvsepTaskEvent>? taskStream,
    Widget? child,
  ) {
    final colors = Theme.of(context).colorScheme;
    final separateModeNotifier = widget.playController.separateModeNotifier;

    final isSepFileReady = taskStream == null;
    return ValueListenableBuilder(
      valueListenable: separateModeNotifier,
      builder: (context, isSeparated, child) {
        return [
          SwitchListTile(
            value: isSeparated,
            title: '人声分离模式'.asText(),
            onChanged: isSepFileReady
                ? (value) => separateModeNotifier.value = value
                : null,
          ),
          isSepFileReady
              ? [
                  [
                    Image.asset(
                      'assets/icons/singing.png',
                      width: 24.0,
                      color: colors.onSurfaceVariant,
                    ).padding(left: 12.0),
                    ValueListenableBuilder(
                      valueListenable:
                          widget.playController.vocalVolumeNotifier,
                      builder: (context, volume, child) => Slider(
                        value: volume,
                        onChanged: isSeparated
                            ? widget.playController.setVocalVolume
                            : null,
                      ),
                    ),
                  ].toRow(mainAxisAlignment: .center),
                  [
                    Image.asset(
                      'assets/icons/drum.png',
                      width: 24.0,
                      color: colors.onSurfaceVariant,
                    ).padding(left: 12.0),
                    ValueListenableBuilder(
                      valueListenable:
                          widget.playController.instruVolumeNotifier,
                      builder: (context, volume, child) => Slider(
                        value: volume,
                        onChanged: isSeparated
                            ? widget.playController.setInstruVolume
                            : null,
                      ),
                    ),
                  ].toRow(mainAxisAlignment: .center),
                ].toColumn()
              : [
                      '处理中'.asText(),
                      StreamBuilder(
                        stream: taskStream,
                        builder: (context, snapshot) =>
                            _getMessage(snapshot.data).asText(),
                      ),
                    ]
                    .toColumn(
                      mainAxisAlignment: .center,
                      separator: const SizedBox(height: 8.0),
                    )
                    .expanded(),
        ].toColumn(separator: const SizedBox(height: 16.0));
      },
    );
  }

  String _getMessage(MvsepTaskEvent? event) {
    switch (event) {
      case null:
      case MvsepInitEvent():
        return '正在初始化服务';

      case MvsepLocalQueuedEvent(:final localQueuePosition):
        return '正在等待其他歌曲 (还有 $localQueuePosition 项';

      case MvsepLocalRunningEvent():
        return '正在执行';

      case MvsepUploadingEvent(:final uploadedBytes, :final totalBytes):
        final percent = (uploadedBytes / totalBytes).asPercent;
        return '正在上传 ($percent%)\n'
            '${uploadedBytes.asByteSize} / ${totalBytes.asByteSize}';

      case MvsepRemoteQueuedEvent(:final remoteCurrentOrder):
        return '正在排队 (还有 $remoteCurrentOrder 人)';

      case MvsepRemoteProcessingEvent():
        return '正在分离人声和伴奏';

      case MvsepDownloadingEvent(
        :final vocalDownloadedBytes,
        :final vocalFileBytes,
        :final instruDownloadedBytes,
        :final instruFileBytes,
      ):
        final downloaded = instruDownloadedBytes + vocalDownloadedBytes;
        if (instruFileBytes == null || vocalFileBytes == null) {
          return '正在下载 (已下载${downloaded.asByteSize})';
        }

        final total = instruFileBytes + vocalFileBytes;
        final percent = (downloaded / total).asPercent;
        return '正在下载 ($percent%)\n'
            '${vocalDownloadedBytes.asByteSize} / ${vocalFileBytes.asByteSize}\n'
            '${instruDownloadedBytes.asByteSize} / ${instruFileBytes.asByteSize}';

      case MvsepCompletedEvent():
        return '生成成功！正在加载';
      case MvsepFailedEvent(:final phase, :final error):
        return '失败阶段：$phase\n原因：$error';
    }
  }
}
