import 'dart:math';

class MockData {
  static String get word => 'c' * (_random.nextInt(15) + 1);

  static String words(int count) {
    final min = count * 2;
    final max = count * 15;
    final l = _random.nextInt(max - min + 1) + min;
    return 'c' * l;
  }

  static String sentence({int? minWordsCount, int? maxWordsCount}) {
    const delta = 6;
    if (minWordsCount == null) {
      maxWordsCount ??= 13;
      minWordsCount = min(7, maxWordsCount - delta);
    }
    maxWordsCount ??= max(13, minWordsCount + delta);
    assert(minWordsCount < maxWordsCount);

    final l =
        _random.nextInt(maxWordsCount - minWordsCount + 1) + minWordsCount;
    return 'word ' * l;
  }

  static final _random = Random();
}
