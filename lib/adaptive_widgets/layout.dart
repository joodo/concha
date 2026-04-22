import 'package:flutter/widgets.dart';

enum SizeBreakPoint implements Comparable<SizeBreakPoint> {
  compact(0.0, 600.0),
  medium(600.0, 839.0),
  expanded(840.0, 1199.0),
  large(1200.0, 1599.0),
  extraLarge(1600.0, double.maxFinite);

  final double start, end;
  const SizeBreakPoint(this.start, this.end);

  static SizeBreakPoint fromWidth(double width) =>
      values.firstWhere((bp) => width >= bp.start && width <= bp.end);

  @override
  int compareTo(SizeBreakPoint other) => index.compareTo(other.index);
}

class LayoutSize implements Comparable<LayoutSize> {
  LayoutSize(this.width);
  LayoutSize.fromConstraints(BoxConstraints constraints)
    : width = constraints.maxWidth;

  final double width;
  @override
  int compareTo(other) => width.compareTo(other.width);

  SizeBreakPoint get breakPoint => SizeBreakPoint.fromWidth(width);
}

class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({super.key, required this.builder});
  final Widget Function(BuildContext context, LayoutSize layoutSize) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          builder(context, LayoutSize.fromConstraints(constraints)),
    );
  }
}
