class ChunkCacheState {
  final Map<int, List<double>> chunks = {};
  final Set<int> _loadingChunks = {};
  int revision = 0;
  int generation = 0;

  bool get isEmpty => chunks.isEmpty;

  bool hasChunk(int chunkIndex) => chunks.containsKey(chunkIndex);

  bool isLoading(int chunkIndex) => _loadingChunks.contains(chunkIndex);

  void markLoading(int chunkIndex) => _loadingChunks.add(chunkIndex);

  void unmarkLoading(int chunkIndex) => _loadingChunks.remove(chunkIndex);

  void store(int chunkIndex, List<double> samples) {
    chunks[chunkIndex] = samples;
    revision++;
  }

  bool evictOutside(int keepStart, int keepEnd) {
    var removed = false;
    final keys = chunks.keys.toList(growable: false);
    for (final key in keys) {
      if (key < keepStart || key > keepEnd) {
        chunks.remove(key);
        removed = true;
      }
    }

    if (removed) {
      revision++;
    }
    return removed;
  }

  void reset() {
    generation++;
    chunks.clear();
    _loadingChunks.clear();
    revision++;
  }
}
