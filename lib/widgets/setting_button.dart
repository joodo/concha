import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:styled_widget/styled_widget.dart';

import '../utils/utils.dart';

class SettingButton extends StatelessWidget {
  const SettingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      openBuilder: (context, _) => const _SettingDialog(),
      closedShape: const CircleBorder(),
      closedElevation: 0,
      openColor: Theme.of(context).scaffoldBackgroundColor,
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
            PrefKeys.proxy.value,
            decoration: const InputDecoration(
              labelText: '网络代理',
              prefixText: 'http://',
            ),
          ),
          _PrefTextField(
            PrefKeys.acoustKey.value,
            decoration: const InputDecoration(labelText: 'AcoustID API Key'),
          ),
          const Divider().padding(bottom: 24.0),
          Text(
            '歌词服务',
            style: Theme.of(context).textTheme.titleLarge,
          ).padding(bottom: 12.0),
          _PrefTextField(
            PrefKeys.geminiKey.value,
            decoration: const InputDecoration(labelText: 'Gemini Key'),
          ),
          _PrefTextField(
            PrefKeys.translatePrompt.value,
            decoration: const InputDecoration(
              hintText: '翻译语言',
              prefixText: '将歌词翻译成：',
            ),
          ),
          _PrefTextField(
            PrefKeys.speakPrompt.value,
            decoration: const InputDecoration(
              hintText: '朗读歌词要求',
              suffixText: '[单句歌词]',
            ),
          ),
          const Divider(),
          FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final data = snapshot.data!;
              return Text('${data.appName}，版本 ${data.version}');
            },
          ),
        ],
      ),
    );
  }
}

class _PrefTextField extends StatefulWidget {
  final String prefKey;
  final InputDecoration? decoration;

  const _PrefTextField(this.prefKey, {this.decoration});

  @override
  State<_PrefTextField> createState() => _PrefTextFieldState();
}

class _PrefTextFieldState extends State<_PrefTextField> {
  late final _notifier = PreferenceValueNotifier<String>(
    '',
    key: widget.prefKey,
  );
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = _notifier.value;
  }

  @override
  void dispose() {
    _notifier.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      decoration: widget.decoration,
      onChanged: (value) => _notifier.value = value,
    ).constrained(maxWidth: 400.0).alignment(.centerLeft).padding(bottom: 12.0);
  }
}
