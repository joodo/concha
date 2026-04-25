import 'package:flutter/widgets.dart';

extension PercentExtension on double {
  int get asPercent => (this * 100.0).round();
}

extension ByteSizeExtension on int {
  String get asByteSize {
    if (this < 1024) {
      return '$this B';
    } else if (this < 1048576) {
      double kb = this / 1024;
      return '${kb.toStringAsFixed(2)} KB';
    } else if (this < 1073741824) {
      double mb = this / 1048576;
      return '${mb.toStringAsFixed(2)} MB';
    } else {
      double gb = this / 1073741824;
      return '${gb.toStringAsFixed(2)} GB';
    }
  }
}

extension DurationExtension on int {
  Duration get seconds => Duration(seconds: this);
  Duration get milliseconds => Duration(milliseconds: this);
}

extension SizedBoxExtension on double {
  SizedBox asWidth() => SizedBox(width: this);
  SizedBox asHeight() => SizedBox(height: this);
}

extension ToUint8Extension on double {
  int get toUint8 => (clamp(0.0, 1.0) * 255).round();
}
