import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:styled_widget/styled_widget.dart';

import '/utils/utils.dart';

class AdaptiveNavigationDestination {
  AdaptiveNavigationDestination({
    required this.title,
    this.subtitle,
    required this.icon,
    this.selectedIcon,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final IconData? selectedIcon;
}

class AdaptiveNavigationPage extends HookWidget {
  const AdaptiveNavigationPage({
    super.key,
    required this.destinations,
    required this.expanded,
    required this.pageBuilder,
    this.title,
  });

  final String? title;
  final List<AdaptiveNavigationDestination> destinations;
  final bool expanded;
  final Widget Function(BuildContext context, int index) pageBuilder;

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState<int>(-1);
    final previousIndex = usePrevious(currentIndex.value);
    final switcherKey = useGlobalKey();

    final displayIndex = expanded
        ? max(currentIndex.value, 0)
        : currentIndex.value;
    final reverse = currentIndex.value < (previousIndex ?? 0);
    final page = PageTransitionSwitcher(
      key: switcherKey,
      reverse: reverse,
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: expanded ? .vertical : .horizontal,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey(displayIndex),
        child: displayIndex == -1
            ? Material(
                child: ListView(
                  children: destinations.indexed
                      .map(
                        (e) => ListTile(
                          leading: Icon(e.$2.icon),
                          title: e.$2.title.asText(),
                          subtitle: e.$2.subtitle?.asText(),
                          onTap: () => currentIndex.value = e.$1,
                        ),
                      )
                      .toList(),
                ),
              )
            : pageBuilder(context, displayIndex),
      ),
    );

    if (!expanded) {
      final appBar = AppBar(
        leading: currentIndex.value == -1
            ? const CloseButton()
            : BackButton(onPressed: () => currentIndex.value = -1),
        title: title?.asText(),
      );
      return Scaffold(appBar: appBar, body: page);
    } else {
      final appBar = AppBar(
        leading: const CloseButton(),
        title: title?.asText(),
        centerTitle: false,
      );

      final listView = Material(
        child: ListTileTheme(
          data: ListTileThemeData(
            selectedTileColor: context.colors.secondaryContainer,
          ),
          child: ListView(
            children: destinations.indexed.map((e) {
              final selected = e.$1 == displayIndex;
              return ListTile(
                leading: selected && e.$2.selectedIcon != null
                    ? Icon(e.$2.selectedIcon)
                    : Icon(e.$2.icon),
                title: e.$2.title.asText(),
                // subtitle: e.$2.subtitle?.asText(),
                selected: selected,
                onTap: () => currentIndex.value = e.$1,
              );
            }).toList(),
          ),
        ),
      );

      return [
        Scaffold(appBar: appBar, body: listView).constrained(width: 200.0),
        page.padding(top: 16.0).expanded(),
      ].toRow();
    }
  }
}
