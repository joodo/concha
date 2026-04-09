import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/llm/llm.dart';
import '/preferences/preferences.dart';
import '/projects/models.dart';
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
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        title: const Text('设置'),
        actions: [CloseButton()],
        actionsPadding: EdgeInsets.symmetric(horizontal: 8.0),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          _PrefTextField(
            .proxy,
            decoration: const InputDecoration(
              labelText: '网络代理',
              prefixText: 'http://',
            ),
          ),
          _PrefTextField(
            .acoustKey,
            decoration: InputDecoration(
              labelText: 'AcoustID API Key',
              helperText: '用于补全音乐信息',
              suffix: TextButton(
                onPressed: () =>
                    launchUrlString('https://acoustid.org/new-application'),
                child: '申请'.asText(),
              ),
            ),
          ),
          _PrefTextField(
            .mvsepKey,
            decoration: InputDecoration(
              labelText: 'MVSEP API Key',
              helperText: '用于生成伴奏',
              suffix: TextButton(
                onPressed: () => launchUrlString('https://mvsep.com/user-api'),
                child: '申请'.asText(),
              ),
            ),
          ),

          _SettingTitle('AI - 文字处理'),
          _PrefDropdownMenu(
            .llmService,
            labelText: '选择服务',
            helperText: '用于理解和翻译歌词',
            data:
                {
                  for (final p in LLMProviderRegistry.getAllProviderInfo())
                    p.id: p,
                }..removeWhere(
                  (key, value) =>
                      !value.supportedCapabilities.contains(LLMCapability.chat),
                ),
            entryBuilder: (key, value) =>
                DropdownMenuEntry(value: key, label: value.displayName),
          ),
          _PrefTextField(
            .translateLang,
            decoration: const InputDecoration(
              hintText: '目标语言',
              prefixText: '翻译语言：',
            ),
          ),
          _PrefTextField(
            .llmKey,
            decoration: InputDecoration(labelText: 'API Key'),
          ),
          _PrefTextField(
            .ttsUrl,
            decoration: InputDecoration(labelText: '服务 URL（可选）'),
          ),
          _PrefTextField(
            .llmModel,
            decoration: InputDecoration(
              labelText: '模型名称',
              hintText: '比如 “gemini-3-flash-preview”',
            ),
          ),
          _TestButton(() => LlmService.fromPref().test(), testName: '文字处理测试'),

          _SettingTitle('AI - 语音生成'),
          _PrefDropdownMenu(
            .ttsService,
            labelText: '选择服务',
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
            decoration: InputDecoration(labelText: '服务 URL（可选）'),
          ),
          _PrefTextField(
            .ttsModel,
            decoration: InputDecoration(
              labelText: '模型名称',
              hintText: '比如 “gemini-2.5-flash-preview-tts”',
            ),
          ),
          _TestButton(() => TtsService.fromPref().test(), testName: '语音测试'),

          _SettingTitle('关于'),
          FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final data = snapshot.data!;
              return Text('${data.appName}，版本 ${data.version}');
            },
          ),
          'Copyright 2026 Joodo. Licensed under GPLv3 License.'.asText(),
          [
            TextButton.icon(
              onPressed: () =>
                  launchUrlString('https://github.com/joodo/concha'),
              label: 'Github'.asText(),
              icon: Icon(Icons.open_in_browser),
            ),
            TextButton.icon(
              onPressed: () => launchUrl(Uri.file(Project.savedDir)),
              label: '本地存储目录'.asText(),
              icon: Icon(Icons.open_in_browser),
            ),
          ].toRow().padding(vertical: 12.0),
        ],
      ),
    );
  }
}

class _SettingTitle extends StatelessWidget {
  const _SettingTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textStyles.titleLarge,
    ).padding(bottom: 12.0, top: 24.0);
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
                await _showResult(context, '${testName ?? "测试"}成功', true);
              } catch (e) {
                if (!context.mounted) return;
                await _showResult(context, '${testName ?? "测试"}失败：\n$e', false);
                rethrow;
              } finally {
                isTesting.value = false;
              }
            },
      child: isTesting.value ? '正在测试'.asText() : '测试'.asText(),
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
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
