import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../widgets/popup_widget.dart';

class ExpansibleButton extends StatefulWidget {
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
  State<ExpansibleButton> createState() => _ExpansibleButtonState();
}

class _ExpansibleButtonState extends State<ExpansibleButton> {
  bool _isShowPop = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isExpanded) {
      return [
        widget.icon.padding(left: 8.0),
        Slider(
          min: widget.min,
          max: widget.max,
          value: widget.value,
          label: widget.labelStringBuilder?.call(widget.value),
          divisions: widget.divisions,
          onChanged: widget.onChanged,
          onChangeStart: widget.onchangeStart,
          onChangeEnd: widget.onChangeEnd,
        ),
      ].toRow(mainAxisSize: .min);
    }

    final link = LayerLink();
    return PopupWidget(
      showing: _isShowPop,
      popupBuilder: (context) =>
          [
                Slider(
                  min: widget.min,
                  max: widget.max,
                  value: widget.value,
                  divisions: widget.divisions,
                  onChanged: widget.onChanged,
                  onChangeStart: widget.onchangeStart,
                  onChangeEnd: widget.onChangeEnd,
                ),
                Text(
                  widget.labelStringBuilder?.call(widget.value) ??
                      widget.value.toString(),
                  maxLines: 1,
                ).constrained(width: 48.0).padding(right: 16.0),
              ]
              .toRow(mainAxisSize: .min)
              .backgroundColor(Theme.of(context).colorScheme.surfaceContainer)
              .clipRRect(all: 16.0),
      layoutBuilder: (context, popup) => GestureDetector(
        behavior: .opaque,
        onTap: () => setState(() {
          _isShowPop = false;
        }),
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
          onPressed: () => setState(() {
            _isShowPop = true;
          }),
          icon: widget.icon,
        ),
      ),
    );
  }
}
