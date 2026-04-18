import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:styled_widget/styled_widget.dart';

import '/generated/l10n.dart';
import '/lyric/lyric.dart';
import '/projects/projects.dart';
import '/utils/utils.dart';

enum _ProjectAction { editLyric, editLyricT }

class ProjectActionsMenu extends ConsumerWidget {
  const ProjectActionsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_ProjectAction>(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: .editLyric,
          onTap: () => _editLyric(ref, isTranslate: false),
          child: S.of(context).editLyric.asText(),
        ),
        PopupMenuItem(
          value: .editLyricT,
          onTap: () => _editLyric(ref, isTranslate: true),
          child: S.of(context).editTranslateLyric.asText(),
        ),
      ],
    );
  }

  Future<void> _editLyric(WidgetRef ref, {required bool isTranslate}) async {
    final lrc = ref
        .read(lyricProvider(ref.projectId!, isTranslate: isTranslate))
        .value;
    final result = await showModal<String>(
      context: ref.context,
      builder: (context) => _LyricEditDialog(initValue: lrc ?? ''),
    );
    if (result == lrc) return;

    ref.lyricNotifier(isTranslate: isTranslate)!.save(result!);
  }
}

class _LyricEditDialog extends HookWidget {
  const _LyricEditDialog({required this.initValue});
  final String initValue;

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController(text: initValue);
    useEffect(() {
      textController.selection = const TextSelection.collapsed(offset: 0);
      return null;
    }, []);

    final textValue = useListenable(textController);

    final canCopy = !textController.selection.isCollapsed;
    final canPaste = useState(false);
    final lifecycleState = useAppLifecycleState();
    useEffect(() {
      _checkClipboard().then(canPaste.set);
      return null;
    }, [textValue.text, lifecycleState]);

    final undoController = useMemoized(() => UndoHistoryController());
    useEffect(() => undoController.dispose, [undoController]);
    final historyValue = useValueListenable(undoController);

    final appBar = AppBar(
      automaticallyImplyLeading: false,
      title: [
        IconButton(
          onPressed: historyValue.canUndo ? undoController.undo : null,
          icon: Icon(Icons.undo),
        ),
        IconButton(
          onPressed: historyValue.canRedo ? undoController.redo : null,
          icon: Icon(Icons.redo),
        ),
        const VerticalDivider(),
        IconButton(
          onPressed: canCopy ? textController.copySelectionToClipboard : null,
          icon: Icon(Icons.copy),
        ),
        IconButton(
          onPressed: canPaste.value ? textController.pasteFromClipboard : null,
          icon: Icon(Icons.paste),
        ),
      ].toRow(),
      actions: [const CloseButton(), 8.0.asWidth()],
    );

    final content = Scaffold(
      appBar: appBar,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: TextField(
          controller: textController,
          undoController: undoController,
          maxLines: null,
          autofocus: true,
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Navigator.pop(context, textValue.text);
      },
      child: content,
    );
  }

  Future<bool> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text?.isNotEmpty ?? false;
  }
}
