import 'dart:io';

import 'package:animations/animations.dart';
import 'package:dio/dio.dart';
import 'package:fireworks/fireworks.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/generated/l10n.dart';
import '/lrclib/lrclib.dart';
import '/play_controller/play_controller.dart';
import '/preferences/preferences.dart';
import '/projects/projects.dart';
import '/utils/utils.dart';

import '../widgets/animated_linear_indicator.dart';
import '../widgets/cancel_text_button.dart';

import 'lyric_field.dart';
import 'utils.dart';

class ContributeButton extends ConsumerWidget {
  const ContributeButton({super.key, required this.lrcModel});
  final LrcModel lrcModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lrcModel.lineTimestampRangeMapping.isEmpty) {
      return 32.0.asHeight();
    }

    final userNameProvider = preferenceProvider<String>(.userName);

    return TextButton.icon(
      label: S.of(context).contribute.asText(),
      onPressed: () async {
        final userName = await showModal<String>(
          context: context,
          builder: (context) => _ContributeDialog(
            lrc: lrcModel.text,
            metadata: ref.project!.metadata,
            duration: ref.playController!.duration,
            userName: _getUserName(ref, userNameProvider),
          ),
        );
        if (userName != null) {
          if (userName.isNotEmpty) {
            ref.read(userNameProvider.notifier).set(userName);
          }
          if (context.mounted) _FireworkOverlay.insertIntoOverlay(context);
        }
      },
      icon: Icon(Icons.volunteer_activism),
    );
  }

  String? _getUserName(WidgetRef ref, PreferenceProvider<String> provider) {
    final envVars = Platform.environment;
    return ref.read(provider) ?? envVars['USERNAME'] ?? envVars['USER'];
  }
}

class _ContributeDialog extends HookWidget {
  const _ContributeDialog({
    required this.lrc,
    required this.metadata,
    required this.duration,
    this.userName,
  });

  final String lrc;
  final Metadata metadata;
  final String? userName;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState<int>(0);
    final previousIndex = usePrevious(currentIndex.value) ?? 0;

    final textControllers = (
      title: useTextEditingController(text: metadata.title),
      artist: useTextEditingController(text: metadata.artist),
      album: useTextEditingController(text: metadata.album),
      userName: useTextEditingController(text: userName),
    );

    final switcher = PageTransitionSwitcher(
      reverse: currentIndex.value < previousIndex,
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) =>
          SharedAxisTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            transitionType: .horizontal,
            child: child,
          ),
      child: KeyedSubtree(
        key: ValueKey(currentIndex.value),
        child: switch (currentIndex.value) {
          0 => _DialogContent(
            title: S.of(context).oneForAllAllForOne,
            content:
                [
                  Builder(
                    builder: (context) {
                      final text = S.of(context).uploadLyricsHint;

                      const host = 'lrclib.net';
                      final index = text.indexOf(host);
                      if (index < 0) return text.asText();

                      return Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: text.substring(0, index)),
                            TextSpan(
                              text: host,
                              style: TextStyle(color: context.colors.primary),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () =>
                                    launchUrlString('https://lrclib.net/'),
                            ),
                            TextSpan(text: text.substring(index + host.length)),
                          ],
                        ),
                        textAlign: .center,
                      );
                    },
                  ),
                  Image.asset(
                    'assets/share.png',
                    fit: .cover,
                    alignment: .topCenter,
                  ).flexible(),
                ].toColumn(
                  separator: 16.0.asHeight(),
                  crossAxisAlignment: .stretch,
                ),
            actions: [
              const CancelTextButton(),
              const Spacer(),
              OutlinedButton(
                onPressed: () => currentIndex.value += 1,
                child: S.of(context).next.asText(),
              ),
            ],
          ),
          1 => _DialogContent(
            title: S.of(context).confirmTrackInfo,
            content: [
              TextField(
                controller: textControllers.title,
                decoration: InputDecoration(labelText: S.of(context).title),
              ),
              TextField(
                controller: textControllers.artist,
                decoration: InputDecoration(labelText: S.of(context).artist),
              ),
              TextField(
                controller: textControllers.album,
                decoration: InputDecoration(labelText: S.of(context).album),
              ),
            ].toColumn(separator: 12.0.asHeight()),
            actions: [
              const CancelTextButton(),
              const Spacer(),
              TextButton(
                onPressed: () => currentIndex.value -= 1,
                child: S.of(context).previous.asText(),
              ),
              OutlinedButton(
                onPressed: () => currentIndex.value += 1,
                child: S.of(context).next.asText(),
              ),
            ],
          ),
          2 => HookBuilder(
            builder: (context) {
              final uploadProgress = useState<double?>(null);
              final isUploading = uploadProgress.value != null;

              final cancelToken = useRef<CancelToken?>(null);

              final failedMessage = useState<String?>(null);

              final content = _DialogContent(
                title: S.of(context).leaveYourNameOptional,
                content: [
                  AnimatedLinearIndicator(
                    isRunning: isUploading,
                    progress: uploadProgress.value,
                  ),
                  TextField(
                    enabled: !isUploading,
                    controller: textControllers.userName,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      errorText: failedMessage.value,
                      errorMaxLines: 7,
                    ),
                  ).padding(horizontal: 36.0),
                ].toColumn(separator: 24.0.asHeight()),
                actions: [
                  TextButton(
                    onPressed: () {
                      final navigator = Navigator.of(context);
                      if (cancelToken.value != null) {
                        cancelToken.value!.cancel();
                        runAfterBuild(navigator.maybePop);
                      } else {
                        navigator.maybePop();
                      }
                    },
                    child: S.of(context).cancel.asText(),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: isUploading
                        ? null
                        : () => currentIndex.value -= 1,
                    child: S.of(context).previous.asText(),
                  ),
                  OutlinedButton(
                    onPressed: isUploading
                        ? null
                        : () async {
                            String? userName = textControllers.userName.text
                                .trim();
                            if (userName.isEmpty) userName = null;

                            final token = CancelToken();
                            cancelToken.value = token;
                            try {
                              await _upload(
                                trackName: textControllers.title.text,
                                artistName: textControllers.title.text,
                                albumName: textControllers.title.text,
                                duration: duration,
                                lrc: lrc,
                                userName: userName,
                                onProgress: uploadProgress.set,
                                cancelToken: token,
                              );
                              if (context.mounted) {
                                uploadProgress.value = null;
                                Navigator.of(context).pop(userName ?? '');
                              }
                            } catch (e) {
                              cancelToken.value = null;
                              uploadProgress.value = null;

                              if (context.mounted) {
                                failedMessage.value = e.toString();
                              }
                              rethrow;
                            }
                          },
                    child: S.of(context).upload.asText(),
                  ),
                ],
              );

              return PopScope(canPop: !isUploading, child: content);
            },
          ),
          int invalid => throw RangeError.range(invalid, 0, 2),
        },
      ),
    );

    return Dialog(
      child: switcher
          .clipRRect(all: 24.0)
          .constrained(maxWidth: 500.0, maxHeight: 350.0),
    );
  }

  Future<void> _upload({
    required String trackName,
    required String artistName,
    required String albumName,
    required Duration duration,
    required String lrc,
    String? userName,
    ValueSetter<double>? onProgress,
    CancelToken? cancelToken,
  }) async {
    final lrcLines = lrc.split('\n');

    if (userName != null) {
      // Add creator tag
      int lastIdTagLine = 0;
      for (int i = 0; i < lrcLines.length; i++) {
        final line = lrcLines[i];

        final tagMatches = LrcRegExps.idTag.allMatches(line);
        if (tagMatches.isNotEmpty) {
          lastIdTagLine = i;
        }

        final timestampMatches = LrcRegExps.timestamp.allMatches(line);
        if (timestampMatches.isNotEmpty) break;
      }

      lrcLines.insert(lastIdTagLine + 1, '[by:$userName]');
      lrc = lrcLines.join('\n');
    }

    String plainLyrics = '';
    for (final line in lrcLines) {
      if (!LrcRegExps.timestamp.hasMatch(line)) continue;
      final text = line.replaceAll(LrcRegExps.timestamp, '').trim();
      plainLyrics += '$text\n';
    }

    final lyric = LrcLibLyric(
      trackName: trackName,
      artistName: artistName,
      albumName: albumName,
      duration: duration,
      plainLyrics: plainLyrics,
      syncedLyrics: lrc,
    );

    return LrcLibService.i.upload(
      lyric,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }
}

class _DialogContent extends StatelessWidget {
  const _DialogContent({
    required this.title,
    required this.actions,
    required this.content,
  });

  final String title;
  final List<Widget> actions;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return [
          title.asText().textStyle(context.textStyles.headlineMedium!),
          content.expanded(),
          actions.toRow(mainAxisAlignment: .end, separator: 8.0.asWidth()),
        ]
        .toColumn(separator: 12.0.asHeight())
        .padding(all: 24.0)
        .backgroundColor(context.colors.surfaceContainer);
  }
}

class _FireworkOverlay extends HookWidget {
  static void insertIntoOverlay(BuildContext context) {
    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _FireworkOverlay(onFinished: overlayEntry.remove),
    );
    Overlay.of(context).insert(overlayEntry);
  }

  const _FireworkOverlay({this.onFinished});

  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    final vsync = useSingleTickerProvider(keys: []);
    final controller = useValue(
      FireworkController(
        vsync: vsync,
        withSky: false,
        withStars: false,
        autoLaunchDuration: 50.milliseconds,
        rocketSpawnTimeout: 50.milliseconds,
      ),
    );

    useEffect(() {
      controller.start();
      Future.delayed(1.seconds, () {
        controller.autoLaunchDuration = Duration.zero;
      });
      Future.delayed(10.seconds, onFinished);
      return controller.dispose;
    }, []);

    return IgnorePointer(child: Fireworks(controller: controller));
  }
}
