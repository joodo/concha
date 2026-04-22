import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:styled_widget/styled_widget.dart';

import '/utils/utils.dart';

typedef AdaptiveListViewBuilder<T> =
    Widget Function(BuildContext context, T data, bool useList);

class AdaptiveListView<T> extends StatelessWidget {
  const AdaptiveListView({
    super.key,
    required this.isList,
    required this.imageBuilder,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.data,
    this.onTap,

    this.gridMaxCrossAxisExtent,
  });

  final AdaptiveListViewBuilder<T> imageBuilder, titleBuilder, subtitleBuilder;
  final List<T> data;
  final bool isList;
  final ValueSetter<T>? onTap;

  final double? gridMaxCrossAxisExtent;

  @override
  Widget build(BuildContext context) {
    if (isList) {
      final listView = ListView.builder(
        padding: EdgeInsets.only(bottom: 16.0),
        itemCount: data.length,
        itemBuilder: (context, index) => ListTile(
          onTap: _getTapHandle(data[index]),
          isThreeLine: true,
          leading: imageBuilder(context, data[index], true),
          title: titleBuilder(context, data[index], true),
          subtitle: subtitleBuilder(context, data[index], true),
        ),
      );
      return Material(child: listView);
    } else {
      return MasonryGridView.builder(
        padding: EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        gridDelegate: SliverSimpleGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: gridMaxCrossAxisExtent ?? 200.0,
        ),
        itemCount: data.length,
        itemBuilder: (context, index) {
          return Card.outlined(
            clipBehavior: .hardEdge,
            child: InkWell(
              onTap: _getTapHandle(data[index]),
              child: [
                imageBuilder(context, data[index], true),
                DefaultTextStyle(
                  style: context.textStyles.bodyLarge!,
                  child: titleBuilder(context, data[index], true),
                ).padding(horizontal: 16.0, top: 8.0),
                DefaultTextStyle(
                  style: context.textStyles.bodyMedium!.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  child: subtitleBuilder(context, data[index], true),
                ).padding(horizontal: 16.0, top: 4.0, bottom: 16.0),
              ].toColumn(crossAxisAlignment: .start),
            ),
          );
        },
      );
    }
  }

  VoidCallback? _getTapHandle(T data) {
    if (onTap == null) return null;
    return () => onTap!(data);
  }
}
