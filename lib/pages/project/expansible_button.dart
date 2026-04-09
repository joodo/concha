import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:styled_widget/styled_widget.dart';

import '/utils/utils.dart';
import '/widgets/popup_widget.dart';

class ExpansibleButton extends HookWidget {
  const ExpansibleButton({
    super.key,
    this.isExpanded = false,
    required this.icon,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
    this.onchangeStart,
    this.onChangeEnd,
    this.labelStringBuilder,
    this.divisions,
  });

  final bool isExpanded;

  final Widget icon;
  final double value, min, max;
  final int? divisions;
  final ValueSetter<double>? onChanged, onchangeStart, onChangeEnd;
  final String Function(double value)? labelStringBuilder;

  @override
  Widget build(BuildContext context) {
    final isPopShowing = useState(false);

    if (isExpanded) {
      return [
        icon.padding(left: 8.0),
        Slider(
          min: min,
          max: max,
          value: value,
          label: labelStringBuilder?.call(value),
          divisions: divisions,
          onChanged: onChanged,
          onChangeStart: onchangeStart,
          onChangeEnd: onChangeEnd,
        ),
      ].toRow(mainAxisSize: .min);
    }

    final link = LayerLink();
    return PopupWidget(
      showing: isPopShowing.value,
      popupBuilder: (context) =>
          [
                Slider(
                  min: min,
                  max: max,
                  value: value,
                  divisions: divisions,
                  onChanged: onChanged,
                  onChangeStart: onchangeStart,
                  onChangeEnd: onChangeEnd,
                ),
                Text(
                  labelStringBuilder?.call(value) ?? value.toString(),
                  maxLines: 1,
                ).constrained(width: 48.0).padding(right: 16.0),
              ]
              .toRow(mainAxisSize: .min)
              .backgroundColor(context.colors.surfaceContainerHighest)
              .clipRRect(all: 16.0),
      layoutBuilder: (context, popup) => GestureDetector(
        behavior: .opaque,
        onTap: () => isPopShowing.value = false,
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
        child: IconButton.filledTonal(
          onPressed: () => isPopShowing.value = true,
          icon: icon,
        ),
      ),
    );
  }
}
