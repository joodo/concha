import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:locale_names/locale_names.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/generated/l10n.dart';
import '/llm/llm.dart';
import '/preferences/preferences.dart' hide Locale;
import '/projects/projects.dart';
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

class SettingDialog extends StatelessWidget {
  const SettingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      leading: const SizedBox.shrink(),
      leadingWidth: 0,
      title: S.of(context).settings.asText(),
      actions: [CloseButton()],
      actionsPadding: EdgeInsets.symmetric(horizontal: 8.0),
    );

    final body = ListView(
      padding: EdgeInsets.all(16.0),
      children: [
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
                    final locale = S.delegate.supportedLocales.firstWhereOrNull(
                      (e) => e.languageCode == value,
                    );
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
            _PrefTextField(
              .acoustKey,
              decoration: InputDecoration(
                labelText: 'AcoustID API Key',
                helperText: S.of(context).functionOfAcoustID,
                suffix: TextButton(
                  onPressed: () =>
                      launchUrlString('https://acoustid.org/new-application'),
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
          title: 'AI - ${S.of(context).textProcessing}',
          children: [
            _PrefDropdownMenu(
              .llmService,
              labelText: S.of(context).selectService,
              helperText: S.of(context).functionOfLlm,
              data:
                  {
                    for (final p in LLMProviderRegistry.getAllProviderInfo())
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
                      onChanged: ref.read(translateLangProvider.notifier).set,
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
                    for (final p in LLMProviderRegistry.getAllProviderInfo())
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

        _SettingSection(
          title: S.of(context).about,
          children: [
            FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final data = snapshot.data!;
                return Text(
                  '${data.appName}，${S.of(context).version} ${data.version}',
                );
              },
            ),
            S.of(context).copyright2026.asText(),
            12.0.asHeight(),
            [
              TextButton.icon(
                onPressed: () =>
                    launchUrlString('https://github.com/joodo/concha'),
                label: 'Github'.asText(),
                icon: Icon(Icons.open_in_browser),
              ),
              TextButton.icon(
                onPressed: () => launchUrl(Uri.file(Project.savedDir)),
                label: S.of(context).localStorageDir.asText(),
                icon: Icon(Icons.open_in_browser),
              ),
            ].toRow(),
          ],
        ),
      ],
    );

    return Scaffold(appBar: appBar, body: body);
  }
}

class _SettingSection extends StatelessWidget {
  const _SettingSection({this.title, required this.children});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return [
      title
              ?.asText()
              .textStyle(context.textStyles.titleLarge!)
              .padding(top: 24.0, bottom: 12.0) ??
          const SizedBox.shrink(),
      children
          .toColumn(crossAxisAlignment: .start)
          .padding(all: 16.0)
          .backgroundColor(context.colors.surfaceContainerLow)
          .clipRRect(all: 16.0),
    ].toColumn(crossAxisAlignment: .start);
  }
}

class _PrefTextField extends StatelessWidget {
  final PrefKey prefKey;
  final InputDecoration? decoration;

  const _PrefTextField(this.prefKey, {this.decoration});

  @override
  Widget build(BuildContext context) {
    return _PrefWidget<String>(
      prefKey: prefKey,
      builder: (initValue, onChanged) =>
          _InitializableTextField(
                initValue: initValue,
                decoration: decoration,
                onChanged: onChanged,
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
  });
  final InputDecoration? decoration;
  final String? initValue;
  final ValueSetter<String> onChanged;

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
