import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:locale_names/locale_names.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/adaptive_widgets/adaptive_widgets.dart';
import '/generated/l10n.dart';
import '/llm/llm.dart';
import '/preferences/preferences.dart' hide Locale;
import '/projects/projects.dart';
import '/services/services.dart';
import '/tts/tts.dart';
import '/utils/utils.dart';

class SettingButton extends StatelessWidget {
  const SettingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      openBuilder: (context, _) => const SettingDialog(),
      closedShape: const CircleBorder(),
      closedElevation: 0,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      closedColor: Colors.transparent,
      closedBuilder: (context, openContainer) {
        return IconButton(
          onPressed: openContainer,
          icon: const Icon(Icons.settings),
        );
      },
    );
  }
}

class SettingDialog extends HookWidget {
  const SettingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final packageInfo = useFuture(useMemoized(PackageInfo.fromPlatform)).data;
    if (packageInfo == null) return const SizedBox.shrink();

    return AdaptiveLayoutBuilder(
      builder: (context, layoutSize) => AdaptiveNavigationPage(
        title: S.of(context).settings,
        expanded: layoutSize.breakPoint > .compact,
        destinations: [
          AdaptiveNavigationDestination(
            title: S.of(context).general,
            icon: Icons.desktop_windows_outlined,
            selectedIcon: Icons.desktop_windows,
          ),
          AdaptiveNavigationDestination(
            title: S.of(context).tools,
            icon: Icons.build_outlined,
            selectedIcon: Icons.build,
          ),
          AdaptiveNavigationDestination(
            title: S.of(context).about,
            icon: Icons.info_outline,
            selectedIcon: Icons.info,
          ),
        ],
        pageBuilder: (context, index) => _SettingPage(
          children: switch (index) {
            0 => [
              _SettingSection(
                title: S.of(context).interface,
                children: [
                  _PrefDropdownMenu(
                    .brightness,
                    labelText: S.of(context).theme,
                    data: {
                      for (final mode in ThemeMode.values)
                        mode.name: switch (mode) {
                          .system => S.of(context).followSystem,
                          .light => S.of(context).light,
                          .dark => S.of(context).dark,
                        },
                    },
                    entryBuilder: (key, value) =>
                        DropdownMenuEntry(value: key, label: value),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      return DropdownMenu<String>(
                        label: S.of(context).language.asText(),
                        initialSelection: ref.read(localeProvider).languageCode,
                        onSelected: (value) {
                          final locale = S.delegate.supportedLocales
                              .firstWhereOrNull((e) => e.languageCode == value);
                          if (locale == null) return;

                          ref.read(localeProvider.notifier).set(locale);
                        },
                        dropdownMenuEntries: S.delegate.supportedLocales
                            .map(
                              (e) => DropdownMenuEntry(
                                value: e.languageCode,
                                label: e.nativeDisplayLanguage,
                              ),
                            )
                            .toList(),
                      ).alignment(.centerLeft).padding(vertical: 12.0);
                    },
                  ),
                ],
              ),
              _SettingSection(
                title: S.of(context).network,
                children: [
                  _PrefTextField(
                    .proxy,
                    decoration: InputDecoration(
                      labelText: S.of(context).networkProxy,
                      prefixText: 'http://',
                    ),
                  ),
                ],
              ),
            ],
            1 => [
              _SettingSection(
                children: [
                  _PrefTextField(
                    .acoustKey,
                    decoration: InputDecoration(
                      labelText: 'AcoustID API Key',
                      helperText: S.of(context).functionOfAcoustID,
                      suffix: TextButton(
                        onPressed: () => launchUrlString(
                          'https://acoustid.org/new-application',
                        ),
                        child: S.of(context).apply.asText(),
                      ),
                    ),
                  ),
                  _PrefTextField(
                    .mvsepKey,
                    decoration: InputDecoration(
                      labelText: 'MVSEP API Key',
                      helperText: S.of(context).functionOfMvsep,
                      suffix: TextButton(
                        onPressed: () =>
                            launchUrlString('https://mvsep.com/user-api'),
                        child: S.of(context).apply.asText(),
                      ),
                    ),
                  ),
                ],
              ),
              _SettingSection(
                title: 'YT-DLP',
                actions: [
                  IconButton(
                    onPressed: () =>
                        launchUrlString('https://github.com/yt-dlp/yt-dlp'),
                    icon: FaIcon(FontAwesomeIcons.github),
                  ),
                ],
                children: [
                  _YtDlpSection().padding(bottom: 24.0),
                  _PrefTextField(
                    .ytDlpExtraArgs,
                    multiLine: true,
                    decoration: InputDecoration(
                      labelText: S.of(context).extraArgs,
                      helperText: S.of(context).separateWithSpace,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              _SettingSection(
                title: 'AI - ${S.of(context).textProcessing}',
                children: [
                  _PrefDropdownMenu(
                    .llmService,
                    labelText: S.of(context).selectService,
                    helperText: S.of(context).functionOfLlm,
                    data:
                        {
                          for (final p
                              in LLMProviderRegistry.getAllProviderInfo())
                            p.id: p,
                        }..removeWhere(
                          (key, value) => !value.supportedCapabilities.contains(
                            LLMCapability.chat,
                          ),
                        ),
                    entryBuilder: (key, value) =>
                        DropdownMenuEntry(value: key, label: value.displayName),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      return _InitializableTextField(
                            initValue: ref.watch(translateLangProvider),
                            decoration: InputDecoration(
                              hintText: S.of(context).targetLanguage,
                              prefixText: S.of(context).translateTo,
                            ),
                            onChanged: ref
                                .read(translateLangProvider.notifier)
                                .set,
                          )
                          .constrained(maxWidth: 400.0)
                          .alignment(.centerLeft)
                          .padding(bottom: 12.0);
                    },
                  ),
                  _PrefTextField(
                    .llmKey,
                    decoration: InputDecoration(labelText: 'API Key'),
                  ),
                  _PrefTextField(
                    .ttsUrl,
                    decoration: InputDecoration(
                      labelText: S.of(context).optionalServiceUrl,
                    ),
                  ),
                  _PrefTextField(
                    .llmModel,
                    decoration: InputDecoration(
                      labelText: S.of(context).modelName,
                      hintText: S.of(context).llmModelExample,
                    ),
                  ),
                  _TestButton(
                    () => LlmService.fromPref().test(),
                    testName: S.of(context).textProcessingTest,
                  ),
                ],
              ),

              _SettingSection(
                title: 'AI - ${S.of(context).voiceGeneration}',
                children: [
                  _PrefDropdownMenu(
                    .ttsService,
                    labelText: S.of(context).selectService,
                    data:
                        {
                          for (final p
                              in LLMProviderRegistry.getAllProviderInfo())
                            p.id: p,
                        }..removeWhere(
                          (key, value) =>
                              key != 'google' &&
                              key != 'openrouter' &&
                              !value.supportedCapabilities.contains(
                                LLMCapability.textToSpeech,
                              ),
                        ),
                    entryBuilder: (key, value) =>
                        DropdownMenuEntry(value: key, label: value.displayName),
                  ),
                  _PrefTextField(
                    .ttsKey,
                    decoration: InputDecoration(labelText: 'API Key'),
                  ),
                  _PrefTextField(
                    .ttsUrl,
                    decoration: InputDecoration(
                      labelText: S.of(context).optionalServiceUrl,
                    ),
                  ),
                  _PrefTextField(
                    .ttsModel,
                    decoration: InputDecoration(
                      labelText: S.of(context).modelName,
                      hintText: S.of(context).ttsModelExample,
                    ),
                  ),
                  _TestButton(
                    () => TtsService.fromPref().test(),
                    testName: S.of(context).voiceTest,
                  ),
                ],
              ),
            ],
            2 => [
              _SettingSection(
                title: S.of(context).about,
                children: [
                  '${packageInfo.appName}，${S.of(context).version} ${packageInfo.version}'
                      .asText(),
                  S.of(context).copyright2026.asText(),
                ],
              ),
              [
                TextButton.icon(
                  onPressed: () =>
                      launchUrlString('https://github.com/joodo/concha'),
                  label: 'Github'.asText(),
                  icon: FaIcon(FontAwesomeIcons.github),
                ),
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.file(Project.savedDir)),
                  label: S.of(context).localStorageDir.asText(),
                  icon: Icon(Icons.folder_open),
                ),
                TextButton.icon(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationIcon: Image.asset(
                      'assets/icon.png',
                    ).constrained(width: 128.0).padding(all: 16.0),
                    applicationVersion: packageInfo.version,
                  ),
                  label: S.of(context).showLicense.asText(),
                  icon: Icon(Icons.description),
                ),
              ].toWrap().padding(left: 8.0),
            ],
            int() => throw UnimplementedError(),
          },
        ),
      ),
    );
  }
}

class _YtDlpSection extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final service = useValue(YoutubeDownloadService());

    final infoFuture = useState(service.executableInfo());
    final infoSnapshot = useFuture(infoFuture.value, preserveState: false);

    final operating = useState(false);
    final operationError = useState<String?>(null);

    final downloadProgress = useState<double?>(null);

    if (infoSnapshot.connectionState == .waiting) return '...'.asText();
    final info = infoSnapshot.data;

    final exeFounded = info != null;

    final infoText = exeFounded
        ? S
              .of(context)
              .ytDlpInfo(info.usingLocal.toString(), info.version)
              .asText()
        : downloadProgress.value.mapOrNull((v) {
                final percent = v * 100;
                final text = percent.toStringAsFixed(1);
                return '$text %'.asText();
              }) ??
              S.of(context).noExecutableFound.asText();

    final button = TextButton(
      onPressed: operating.value
          ? null
          : () async {
              operationError.clear();

              try {
                operating.value = true;
                final operation = exeFounded
                    ? service.upgrade()
                    : service.downloadPrebuiltYtDlp(
                        onProgress: downloadProgress.set,
                      );
                await operation;
                infoFuture.value = service.executableInfo();
              } catch (e) {
                operationError.value = e.toString();
              } finally {
                operating.value = false;
                downloadProgress.value = null;
              }
            },
      child: _getButtonText(context, exeFounded, operating.value).asText(),
    );

    final hint = operationError.value == null
        ? Text(
            exeFounded
                ? S.of(context).ytDlpUpgradingHint
                : S.of(context).ytDlpUseHint,
            style: context.textStyles.labelMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          )
        : operationError.value!.asText().textStyle(
            context.textStyles.bodyMedium!.copyWith(
              color: context.colors.error,
            ),
          );

    return [
      [infoText, button].toRow(separator: 12.0.asWidth()),
      hint,
    ].toColumn(crossAxisAlignment: .start, separator: 4.0.asHeight());
  }

  String _getButtonText(BuildContext context, bool exeFound, bool operating) {
    if (exeFound) {
      return operating ? S.of(context).upgrading : S.of(context).upgrade;
    } else {
      return operating ? S.of(context).downloading : S.of(context).download;
    }
  }
}

class _SettingPage extends StatelessWidget {
  const _SettingPage({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final content = children
        .toColumn(crossAxisAlignment: .start, separator: 16.0.asHeight())
        .padding(horizontal: 16.0, bottom: 16.0);
    return SingleChildScrollView(
      child: content.alignment(.topLeft),
    ).alignment(.topLeft);
  }
}

class _SettingSection extends StatelessWidget {
  const _SettingSection({this.title, required this.children, this.actions});
  final String? title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return [
      [
        ?title?.asText().textStyle(context.textStyles.titleLarge!),
        if (actions?.isNotEmpty == true) 12.0.asWidth(),
        ...?actions,
      ].toWrap(crossAxisAlignment: .center).padding(bottom: 12.0),
      children
          .toColumn(crossAxisAlignment: .start)
          .padding(all: 16.0)
          .backgroundColor(context.colors.surfaceContainerLow)
          .clipRRect(all: 16.0),
    ].toColumn(crossAxisAlignment: .start).constrained(maxWidth: 600.0);
  }
}

class _PrefTextField extends StatelessWidget {
  const _PrefTextField(this.prefKey, {this.decoration, this.multiLine});
  final PrefKey prefKey;
  final InputDecoration? decoration;
  final bool? multiLine;

  @override
  Widget build(BuildContext context) {
    return _PrefWidget<String>(
      prefKey: prefKey,
      builder: (initValue, onChanged) =>
          _InitializableTextField(
                initValue: initValue,
                decoration: decoration,
                onChanged: onChanged,
                multiLine: multiLine,
              )
              .constrained(maxWidth: 400.0)
              .alignment(.centerLeft)
              .padding(bottom: 12.0),
    );
  }
}

class _PrefDropdownMenu<T> extends StatelessWidget {
  final PrefKey prefKey;
  final Map<String, T> data;
  final DropdownMenuEntry<String> Function(String key, T value) entryBuilder;
  final String? labelText, helperText;

  const _PrefDropdownMenu(
    this.prefKey, {
    required this.data,
    required this.entryBuilder,
    this.labelText,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return _PrefWidget<String>(
      prefKey: prefKey,
      builder: (initValue, onChanged) {
        return DropdownMenu<String>(
          label: labelText?.asText(),
          helperText: helperText,
          initialSelection: initValue,
          onSelected: (value) => value.mapOrNull(onChanged),
          dropdownMenuEntries: data.entries
              .map((e) => entryBuilder(e.key, e.value))
              .toList(),
        ).alignment(.centerLeft).padding(vertical: 12.0);
      },
    );
  }
}

class _PrefWidget<T> extends ConsumerWidget {
  const _PrefWidget({required this.prefKey, required this.builder});
  final PrefKey prefKey;
  final Widget Function(T? initValue, ValueSetter<T> onChanged) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return builder(
      ref.read(_provider),
      (value) => ref.read(_provider.notifier).set(value),
    );
  }

  PreferenceProvider<T> get _provider => preferenceProvider<T>(prefKey);
}

class _InitializableTextField extends HookWidget {
  const _InitializableTextField({
    required this.decoration,
    required this.initValue,
    required this.onChanged,
    this.multiLine,
  });
  final InputDecoration? decoration;
  final String? initValue;
  final ValueSetter<String> onChanged;
  final bool? multiLine;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initValue);
    useEffect(() {
      if (initValue != controller.text) {
        controller.text = initValue ?? '';
      }
      return null;
    }, [initValue]);
    return TextField(
      controller: controller,
      decoration: decoration,
      onChanged: onChanged,
      maxLines: multiLine == true ? null : 1,
    );
  }
}

class _TestButton extends HookWidget {
  const _TestButton(this.test, {this.testName});

  final Future<void> Function() test;
  final String? testName;

  @override
  Widget build(BuildContext context) {
    final isTesting = useState(false);

    return OutlinedButton(
      onPressed: isTesting.value
          ? null
          : () async {
              isTesting.value = true;
              try {
                await test();
                if (!context.mounted) return;
                await _showResult(
                  context,
                  '${testName ?? S.of(context).test}${S.of(context).successOfTest}',
                  true,
                );
              } catch (e) {
                if (!context.mounted) return;
                await _showResult(
                  context,
                  '${testName ?? S.of(context).test}${S.of(context).failureOfTest}\n$e',
                  false,
                );
                rethrow;
              } finally {
                isTesting.value = false;
              }
            },
      child: isTesting.value
          ? S.of(context).testing.asText()
          : S.of(context).test.asText(),
    ).alignment(.centerLeft);
  }

  Future<void> _showResult(BuildContext context, String message, bool success) {
    return showModal(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(success ? Icons.check : Icons.error),
        content: message.asText(),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: S.of(context).confirm.asText(),
          ),
        ],
      ),
    );
  }
}
