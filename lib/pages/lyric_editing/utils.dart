class LrcRegExps {
  static final timestamp = RegExp(r'\[(\d{1,}):(\d{2})(?:\.(\d{1,}))?\]');
  static final idTag = RegExp(r'\[([a-z]+):(.*)\]');
}
