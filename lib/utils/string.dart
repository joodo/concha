extension StringProcessExtension on String {
  int lineIndexAt(int index) {
    if (index < 0 || index > length) {
      throw RangeError.range(index, 0, length, "index");
    }

    int lineCount = 0;
    for (int i = 0; i < index; i++) {
      if (codeUnitAt(i) == 10) {
        lineCount++;
      }
    }
    return lineCount;
  }
}
