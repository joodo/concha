import 'dart:io';

import 'models/models.dart';
import 'services/gemini_service.dart';

extension GenerateSummaryExtension on Project {
  Future<void> generateSummary() async {
    final file = File(path.lyric);
    if (!await file.exists()) return;

    final lrc = await file.readAsString();
    final summary = await GeminiService.i.summary(lrc);
    if (summary.isNotEmpty) this.summary = summary;
  }
}
