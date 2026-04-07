import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/preferences/preferences.dart';
import '/projects/models.dart';
import '/utils/utils.dart';

class SettingButton extends StatelessWidget {
  const SettingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      openBuilder: (context, _) => const _SettingDialog(),
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

class _SettingDialog extends StatelessWidget {
  const _SettingDialog();

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

          Text(
            '歌词服务',
            style: Theme.of(context).textTheme.titleLarge,
          ).padding(bottom: 12.0, top: 24.0),
          _PrefTextField(
            .geminiKey,
            decoration: InputDecoration(
              labelText: 'Gemini Key',
              suffix: TextButton(
                onPressed: () =>
                    launchUrlString('https://aistudio.google.com/api-keys'),
                child: '申请'.asText(),
              ),
            ),
          ),
          _PrefTextField(
            .translateLang,
            decoration: const InputDecoration(
              hintText: '翻译语言',
              prefixText: '将歌词翻译成：',
            ),
          ),
          _PrefTextField(
            .speakPrompt,
            decoration: const InputDecoration(
              hintText: '朗读歌词要求',
              suffixText: '[单句歌词]',
            ),
          ),

          Text(
            '关于',
            style: Theme.of(context).textTheme.titleLarge,
          ).padding(bottom: 12.0, top: 24.0),
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

class _PrefTextField extends HookConsumerWidget {
  final PrefKey prefKey;
  final InputDecoration? decoration;

  const _PrefTextField(this.prefKey, {this.decoration});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(text: ref.read(_provider));
    return TextField(
      controller: controller,
      decoration: decoration,
      onChanged: (value) => ref.read(_provider.notifier).set(value),
    ).constrained(maxWidth: 400.0).alignment(.centerLeft).padding(bottom: 12.0);
  }

  PreferenceProvider<String> get _provider =>
      preferenceProvider<String>(prefKey);
}
